'use client';

import React, { useState } from 'react';
import { useDashboardStore } from '../store/useStore';
import { cleanData } from '../utils/dataProcessing';
import styles from './DataQualityReport.module.css';

export default function DataQualityReport() {
    const { rawData, dataQualityReport, setCleanData } = useDashboardStore();
    const [cleaningStrategy, setCleaningStrategy] = useState<'drop' | 'impute'>('drop');
    const [isCleaning, setIsCleaning] = useState(false);

    if (!dataQualityReport || rawData.length === 0) {
        return (
            <div className={styles.empty}>
                <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
                    <circle cx="32" cy="32" r="30" stroke="var(--border-default)" strokeWidth="2" />
                    <path d="M32 20v24M20 32h24" stroke="var(--text-muted)" strokeWidth="2" strokeLinecap="round" />
                </svg>
                <h3>No Data Loaded</h3>
                <p>Upload a dataset to see quality metrics</p>
            </div>
        );
    }

    const handleCleanData = () => {
        setIsCleaning(true);
        setTimeout(() => {
            const cleaned = cleanData(rawData, cleaningStrategy);
            setCleanData(cleaned);
            setIsCleaning(false);
        }, 500);
    };

    const { totalRows, totalColumns, issues, completeness } = dataQualityReport;
    const hasIssues = issues.length > 0;

    return (
        <div className={styles.container}>
            <div className={styles.header}>
                <h2>Data Quality Report</h2>
                <div className={styles.badge}>
                    {completeness >= 90 ? '✓ Excellent' : completeness >= 70 ? '⚠ Good' : '✗ Needs Attention'}
                </div>
            </div>

            <div className={styles.stats}>
                <div className={styles.statCard}>
                    <div className={styles.statValue}>{totalRows.toLocaleString()}</div>
                    <div className={styles.statLabel}>Total Rows</div>
                </div>

                <div className={styles.statCard}>
                    <div className={styles.statValue}>{totalColumns}</div>
                    <div className={styles.statLabel}>Columns</div>
                </div>

                <div className={styles.statCard}>
                    <div className={styles.statValue}>{completeness.toFixed(1)}%</div>
                    <div className={styles.statLabel}>Completeness</div>
                    <div className={styles.progressBar}>
                        <div
                            className={styles.progressFill}
                            style={{ width: `${completeness}%` }}
                        ></div>
                    </div>
                </div>

                <div className={styles.statCard}>
                    <div className={styles.statValue}>{issues.length}</div>
                    <div className={styles.statLabel}>Issues Found</div>
                </div>
            </div>

            {hasIssues && (
                <>
                    <div className={styles.issuesSection}>
                        <h3>Data Quality Issues</h3>
                        <div className={styles.issuesList}>
                            {issues.map((issue, index) => (
                                <div key={index} className={styles.issueCard}>
                                    <div className={styles.issueHeader}>
                                        <div className={styles.issueType}>
                                            {issue.type === 'missing' && '⚠ Missing Values'}
                                            {issue.type === 'type_mismatch' && '⚡ Type Mismatch'}
                                            {issue.type === 'outlier' && '📊 Outliers'}
                                        </div>
                                        <div className={styles.issueColumn}>{issue.column}</div>
                                    </div>
                                    <div className={styles.issueDetails}>
                                        <span>{issue.count} rows affected</span>
                                        <span className={styles.percentage}>{issue.percentage.toFixed(1)}%</span>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>

                    <div className={styles.cleaningSection}>
                        <h3>Data Cleaning</h3>
                        <p className={styles.description}>
                            Choose a strategy to handle missing values and inconsistencies
                        </p>

                        <div className={styles.strategies}>
                            <button
                                className={`${styles.strategyCard} ${cleaningStrategy === 'drop' ? styles.selected : ''}`}
                                onClick={() => setCleaningStrategy('drop')}
                            >
                                <div className={styles.strategyIcon}>🗑️</div>
                                <div className={styles.strategyTitle}>Drop Rows</div>
                                <div className={styles.strategyDesc}>Remove rows with missing values</div>
                            </button>

                            <button
                                className={`${styles.strategyCard} ${cleaningStrategy === 'impute' ? styles.selected : ''}`}
                                onClick={() => setCleaningStrategy('impute')}
                            >
                                <div className={styles.strategyIcon}>🔧</div>
                                <div className={styles.strategyTitle}>Impute Values</div>
                                <div className={styles.strategyDesc}>Fill missing values with mean/mode</div>
                            </button>
                        </div>

                        <button
                            className={styles.cleanButton}
                            onClick={handleCleanData}
                            disabled={isCleaning}
                        >
                            {isCleaning ? 'Cleaning...' : 'Clean Data'}
                        </button>
                    </div>
                </>
            )}

            {!hasIssues && (
                <div className={styles.successMessage}>
                    <svg width="48" height="48" viewBox="0 0 48 48" fill="none">
                        <circle cx="24" cy="24" r="22" fill="var(--accent-success)" opacity="0.1" />
                        <path d="M14 24l8 8 12-12" stroke="var(--accent-success)" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" />
                    </svg>
                    <h3>Data Quality Excellent!</h3>
                    <p>No issues detected in your dataset</p>
                </div>
            )}
        </div>
    );
}
