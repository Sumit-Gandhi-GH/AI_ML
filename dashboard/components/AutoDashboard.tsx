'use client';

import React, { useEffect, useState } from 'react';
import { useDashboardStore } from '../store/useStore';
import { generateAutomatedInsights, DataInsight } from '../utils/analytics';
import { detectColumnType } from '../utils/dataProcessing';
import ChartRenderer from './ChartRenderer';
import styles from './AutoDashboard.module.css';

export default function AutoDashboard() {
    const { cleanData, columns, addChart } = useDashboardStore();
    const [insights, setInsights] = useState<DataInsight[]>([]);
    const [isGenerating, setIsGenerating] = useState(false);
    const [dataContext, setDataContext] = useState('');

    useEffect(() => {
        if (cleanData.length > 0) {
            const generatedInsights = generateAutomatedInsights(cleanData, columns);
            setInsights(generatedInsights);
        }
    }, [cleanData, columns]);

    const handleGenerateAutoDashboard = () => {
        setIsGenerating(true);

        setTimeout(() => {
            // Identify numeric and categorical columns
            const numericCols: string[] = [];
            const categoricalCols: string[] = [];

            columns.forEach(col => {
                const type = detectColumnType(cleanData, col);
                if (type === 'number') {
                    numericCols.push(col);
                } else {
                    categoricalCols.push(col);
                }
            });

            // Generate automatic charts based on data structure
            const autoCharts = [];

            // 1. Distribution chart for first categorical column
            if (categoricalCols.length > 0 && numericCols.length > 0) {
                autoCharts.push({
                    id: `auto-${Date.now()}-1`,
                    type: 'bar' as const,
                    xAxis: categoricalCols[0],
                    yAxis: numericCols[0],
                    aggregation: 'sum' as const,
                    title: `${numericCols[0]} by ${categoricalCols[0]}`,
                });
            }

            // 2. Pie chart for distribution
            if (categoricalCols.length > 0) {
                autoCharts.push({
                    id: `auto-${Date.now()}-2`,
                    type: 'pie' as const,
                    xAxis: categoricalCols[0],
                    yAxis: numericCols[0] || categoricalCols[0],
                    aggregation: numericCols.length > 0 ? 'sum' as const : 'count' as const,
                    title: `Distribution of ${categoricalCols[0]}`,
                });
            }

            // 3. Trend line if we have multiple numeric columns
            if (numericCols.length >= 2) {
                autoCharts.push({
                    id: `auto-${Date.now()}-3`,
                    type: 'line' as const,
                    xAxis: categoricalCols[0] || columns[0],
                    yAxis: numericCols[1],
                    aggregation: 'avg' as const,
                    title: `${numericCols[1]} Trend`,
                });
            }

            // 4. Area chart for cumulative view
            if (categoricalCols.length > 0 && numericCols.length > 0) {
                autoCharts.push({
                    id: `auto-${Date.now()}-4`,
                    type: 'area' as const,
                    xAxis: categoricalCols[0],
                    yAxis: numericCols[0],
                    aggregation: 'sum' as const,
                    title: `${numericCols[0]} Overview`,
                });
            }

            // Add charts to store
            autoCharts.forEach(chart => addChart(chart));

            setIsGenerating(false);
        }, 1500);
    };

    if (cleanData.length === 0) {
        return (
            <div className={styles.empty}>
                <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
                    <rect width="64" height="64" rx="16" fill="var(--bg-elevated)" />
                    <path d="M20 44V20h4v24h-4zM28 44V28h4v16h-4zM36 44V32h4v12h-4zM44 44V24h4v20h-4z" fill="var(--text-muted)" />
                </svg>
                <h3>No Data Available</h3>
                <p>Upload your data to see automated insights and dashboard</p>
            </div>
        );
    }

    return (
        <div className={styles.container}>
            <div className={styles.header}>
                <div>
                    <h2>📊 Auto-Generated Dashboard</h2>
                    <p className={styles.subtitle}>AI-powered insights and visualizations based on your data</p>
                </div>
                <button className={styles.generateButton} onClick={handleGenerateAutoDashboard} disabled={isGenerating}>
                    {isGenerating ? (
                        <>
                            <div className={styles.spinner}></div>
                            Generating...
                        </>
                    ) : (
                        <>
                            <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                                <path fillRule="evenodd" d="M4 2a1 1 0 011 1v2.101a7.002 7.002 0 0111.601 2.566 1 1 0 11-1.885.666A5.002 5.002 0 005.999 7H9a1 1 0 010 2H4a1 1 0 01-1-1V3a1 1 0 011-1zm.008 9.057a1 1 0 011.276.61A5.002 5.002 0 0014.001 13H11a1 1 0 110-2h5a1 1 0 011 1v5a1 1 0 11-2 0v-2.101a7.002 7.002 0 01-11.601-2.566 1 1 0 01.61-1.276z" clipRule="evenodd" />
                            </svg>
                            Generate Dashboard
                        </>
                    )}
                </button>
            </div>

            {/* Data Context Input */}
            <div className={styles.contextSection}>
                <label>📝 What does this data represent?</label>
                <input
                    type="text"
                    placeholder="e.g., Sales data for Q4 2024, Employee performance metrics, Customer feedback..."
                    value={dataContext}
                    onChange={(e) => setDataContext(e.target.value)}
                    className={styles.contextInput}
                />
                <p className={styles.contextHint}>
                    Providing context helps generate more relevant visualizations and insights
                </p>
            </div>

            {/* Insights Section */}
            <div className={styles.insightsSection}>
                <h3>🔍 Key Insights</h3>
                <div className={styles.insightsGrid}>
                    {insights.slice(0, 6).map((insight, index) => (
                        <div key={index} className={`${styles.insightCard} ${styles[insight.type]}`}>
                            <div className={styles.insightHeader}>
                                <span className={styles.insightType}>
                                    {insight.type === 'trend' && '📈'}
                                    {insight.type === 'distribution' && '📊'}
                                    {insight.type === 'outlier' && '⚠️'}
                                    {insight.type === 'correlation' && '🔗'}
                                    {insight.type === 'summary' && '📋'}
                                </span>
                                <span className={styles.confidence}>{(insight.confidence * 100).toFixed(0)}%</span>
                            </div>
                            <h4>{insight.title}</h4>
                            <p>{insight.description}</p>
                        </div>
                    ))}
                </div>
            </div>

            {/* Quick Stats */}
            <div className={styles.statsSection}>
                <div className={styles.statCard}>
                    <div className={styles.statValue}>{cleanData.length.toLocaleString()}</div>
                    <div className={styles.statLabel}>Total Records</div>
                </div>
                <div className={styles.statCard}>
                    <div className={styles.statValue}>{columns.length}</div>
                    <div className={styles.statLabel}>Columns</div>
                </div>
                <div className={styles.statCard}>
                    <div className={styles.statValue}>{columns.filter(c => detectColumnType(cleanData, c) === 'number').length}</div>
                    <div className={styles.statLabel}>Numeric Fields</div>
                </div>
                <div className={styles.statCard}>
                    <div className={styles.statValue}>{insights.length}</div>
                    <div className={styles.statLabel}>Insights Found</div>
                </div>
            </div>
        </div>
    );
}
