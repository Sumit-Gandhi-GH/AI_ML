'use client';

import React, { useState } from 'react';
import { useDashboardStore } from '../store/useStore';
import styles from './CustomRequestModal.module.css';

interface CustomRequestModalProps {
    onClose: () => void;
}

export default function CustomRequestModal({ onClose }: CustomRequestModalProps) {
    const { columns, addChart } = useDashboardStore();
    const [request, setRequest] = useState('');
    const [isProcessing, setIsProcessing] = useState(false);

    const handleSubmit = () => {
        if (!request.trim()) return;

        setIsProcessing(true);

        // Mock AI processing - in a real app, this would call an AI service
        setTimeout(() => {
            // Simple keyword matching for demo
            const lowerRequest = request.toLowerCase();
            let chartType: 'bar' | 'line' | 'pie' | 'area' = 'bar';
            let xAxis = columns[0] || '';
            let yAxis = columns[1] || '';

            if (lowerRequest.includes('pie') || lowerRequest.includes('distribution')) {
                chartType = 'pie';
            } else if (lowerRequest.includes('line') || lowerRequest.includes('trend')) {
                chartType = 'line';
            } else if (lowerRequest.includes('area')) {
                chartType = 'area';
            }

            // Try to extract column names from request
            columns.forEach(col => {
                if (lowerRequest.includes(col.toLowerCase())) {
                    if (!xAxis) xAxis = col;
                    else if (!yAxis) yAxis = col;
                }
            });

            addChart({
                id: Date.now().toString(),
                type: chartType,
                xAxis,
                yAxis,
                aggregation: 'sum',
                title: request.slice(0, 50),
            });

            setIsProcessing(false);
            onClose();
        }, 1500);
    };

    return (
        <div className={styles.overlay} onClick={onClose}>
            <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
                <div className={styles.header}>
                    <div>
                        <h2>Custom Visualization Request</h2>
                        <p className={styles.subtitle}>Describe the chart you want to create</p>
                    </div>
                    <button className={styles.closeButton} onClick={onClose}>
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                            <path d="M6 18L18 6M6 6l12 12" strokeWidth="2" strokeLinecap="round" />
                        </svg>
                    </button>
                </div>

                <div className={styles.content}>
                    <textarea
                        className={styles.textarea}
                        placeholder="e.g., Show me a bar chart of sales by region..."
                        value={request}
                        onChange={(e) => setRequest(e.target.value)}
                        rows={6}
                        disabled={isProcessing}
                    />

                    <div className={styles.examples}>
                        <div className={styles.examplesTitle}>Examples:</div>
                        <button
                            className={styles.exampleChip}
                            onClick={() => setRequest(`Show me ${columns[0]} by ${columns[1]}`)}
                        >
                            Show me {columns[0]} by {columns[1]}
                        </button>
                        <button
                            className={styles.exampleChip}
                            onClick={() => setRequest('Create a pie chart distribution')}
                        >
                            Create a pie chart distribution
                        </button>
                        <button
                            className={styles.exampleChip}
                            onClick={() => setRequest('Line chart showing trends over time')}
                        >
                            Line chart showing trends
                        </button>
                    </div>
                </div>

                <div className={styles.footer}>
                    <button className={styles.cancelButton} onClick={onClose} disabled={isProcessing}>
                        Cancel
                    </button>
                    <button
                        className={styles.generateButton}
                        onClick={handleSubmit}
                        disabled={!request.trim() || isProcessing}
                    >
                        {isProcessing ? 'Generating...' : 'Generate Chart'}
                    </button>
                </div>
            </div>
        </div>
    );
}
