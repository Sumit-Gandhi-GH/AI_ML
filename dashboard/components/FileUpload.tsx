'use client';

import React, { useCallback, useState } from 'react';
import Papa from 'papaparse';
import { useDashboardStore } from '../store/useStore';
import { analyzeDataQuality } from '../utils/dataProcessing';
import styles from './FileUpload.module.css';

export default function FileUpload() {
    const [isDragging, setIsDragging] = useState(false);
    const [isProcessing, setIsProcessing] = useState(false);
    const { setRawData, setCleanData, setColumns, setDataQualityReport } = useDashboardStore();

    const processFile = useCallback((file: File) => {
        setIsProcessing(true);

        Papa.parse(file, {
            header: true,
            dynamicTyping: true,
            skipEmptyLines: true,
            complete: (results) => {
                const data = results.data as any[];
                const columns = results.meta.fields || [];

                setRawData(data);
                setCleanData(data);
                setColumns(columns);

                // Analyze data quality
                const qualityReport = analyzeDataQuality(data);
                setDataQualityReport(qualityReport);

                setIsProcessing(false);
            },
            error: (error) => {
                console.error('Error parsing CSV:', error);
                setIsProcessing(false);
            },
        });
    }, [setRawData, setCleanData, setColumns, setDataQualityReport]);

    const handleDrop = useCallback((e: React.DragEvent) => {
        e.preventDefault();
        setIsDragging(false);

        const file = e.dataTransfer.files[0];
        if (file && (file.type === 'text/csv' || file.name.endsWith('.csv'))) {
            processFile(file);
        }
    }, [processFile]);

    const handleDragOver = useCallback((e: React.DragEvent) => {
        e.preventDefault();
        setIsDragging(true);
    }, []);

    const handleDragLeave = useCallback((e: React.DragEvent) => {
        e.preventDefault();
        setIsDragging(false);
    }, []);

    const handleFileSelect = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            processFile(file);
        }
    }, [processFile]);

    return (
        <div className={styles.container}>
            <div
                className={`${styles.dropzone} ${isDragging ? styles.dragging : ''} ${isProcessing ? styles.processing : ''}`}
                onDrop={handleDrop}
                onDragOver={handleDragOver}
                onDragLeave={handleDragLeave}
            >
                {isProcessing ? (
                    <div className={styles.processingState}>
                        <div className={styles.spinner}></div>
                        <h3>Processing your data...</h3>
                        <p>This may take a moment</p>
                    </div>
                ) : (
                    <>
                        <div className={styles.uploadIcon}>
                            <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
                                <rect width="64" height="64" rx="16" fill="var(--bg-elevated)" />
                                <path
                                    d="M32 20L42 30H36V44H28V30H22L32 20Z"
                                    fill="url(#uploadGradient)"
                                />
                                <defs>
                                    <linearGradient id="uploadGradient" x1="22" y1="20" x2="42" y2="44">
                                        <stop offset="0%" stopColor="#6366f1" />
                                        <stop offset="100%" stopColor="#8b5cf6" />
                                    </linearGradient>
                                </defs>
                            </svg>
                        </div>
                        <h3 className={styles.title}>Drop your CSV file here</h3>
                        <p className={styles.subtitle}>or click to browse</p>
                        <input
                            type="file"
                            accept=".csv"
                            onChange={handleFileSelect}
                            className={styles.fileInput}
                        />
                    </>
                )}
            </div>

            <div className={styles.info}>
                <div className={styles.infoCard}>
                    <div className={styles.infoIcon}>
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                    </div>
                    <div>
                        <h4>Supported Format</h4>
                        <p>CSV files with headers</p>
                    </div>
                </div>

                <div className={styles.infoCard}>
                    <div className={styles.infoIcon}>
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                    </div>
                    <div>
                        <h4>Auto-Detection</h4>
                        <p>Column types detected automatically</p>
                    </div>
                </div>

                <div className={styles.infoCard}>
                    <div className={styles.infoIcon}>
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                        </svg>
                    </div>
                    <div>
                        <h4>Secure Processing</h4>
                        <p>All data processed locally</p>
                    </div>
                </div>
            </div>
        </div>
    );
}
