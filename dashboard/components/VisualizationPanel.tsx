'use client';

import React, { useState } from 'react';
import { useDashboardStore, ChartConfig } from '../store/useStore';
import ChartRenderer from './ChartRenderer';
import ChartBuilder from './ChartBuilder';
import CustomRequestModal from './CustomRequestModal';
import styles from './VisualizationPanel.module.css';

export default function VisualizationPanel() {
    const { cleanData, charts, removeChart, comments, addComment } = useDashboardStore();
    const [showBuilder, setShowBuilder] = useState(false);
    const [showCustomRequest, setShowCustomRequest] = useState(false);
    const [selectedChartForComment, setSelectedChartForComment] = useState<string | null>(null);
    const [commentText, setCommentText] = useState('');

    if (cleanData.length === 0) {
        return (
            <div className={styles.empty}>
                <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
                    <rect width="64" height="64" rx="16" fill="var(--bg-elevated)" />
                    <path d="M20 44V20h4v24h-4zM28 44V28h4v16h-4zM36 44V32h4v12h-4zM44 44V24h4v20h-4z" fill="var(--text-muted)" />
                </svg>
                <h3>No Data Available</h3>
                <p>Please upload and clean your data first</p>
            </div>
        );
    }

    const handleAddComment = (chartId: string) => {
        if (commentText.trim()) {
            addComment({
                id: Date.now().toString(),
                chartId,
                text: commentText,
                author: 'User',
                timestamp: Date.now(),
            });
            setCommentText('');
            setSelectedChartForComment(null);
        }
    };

    return (
        <div className={styles.container}>
            <div className={styles.header}>
                <h2>Visualizations</h2>
                <div className={styles.actions}>
                    <button
                        className={styles.actionButton}
                        onClick={() => setShowCustomRequest(true)}
                    >
                        <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                            <path d="M2 5a2 2 0 012-2h7a2 2 0 012 2v4a2 2 0 01-2 2H9l-3 3v-3H4a2 2 0 01-2-2V5z" />
                            <path d="M15 7v2a4 4 0 01-4 4H9.828l-1.766 1.767c.28.149.599.233.938.233h2l3 3v-3h2a2 2 0 002-2V9a2 2 0 00-2-2h-1z" />
                        </svg>
                        Custom Request
                    </button>
                    <button
                        className={styles.primaryButton}
                        onClick={() => setShowBuilder(true)}
                    >
                        <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                            <path fillRule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clipRule="evenodd" />
                        </svg>
                        Add Chart
                    </button>
                </div>
            </div>

            {charts.length === 0 ? (
                <div className={styles.emptyCharts}>
                    <div className={styles.emptyIcon}>📊</div>
                    <h3>No Charts Yet</h3>
                    <p>Create your first visualization using the buttons above</p>
                </div>
            ) : (
                <div className={styles.chartsGrid}>
                    {charts.map((chart) => {
                        const chartComments = comments.filter(c => c.chartId === chart.id);

                        return (
                            <div key={chart.id} className={styles.chartCard}>
                                <div className={styles.chartHeader}>
                                    <h3>{chart.title}</h3>
                                    <div className={styles.chartActions}>
                                        <button
                                            className={styles.iconButton}
                                            onClick={() => setSelectedChartForComment(chart.id)}
                                            title="Add comment"
                                        >
                                            <svg width="18" height="18" viewBox="0 0 20 20" fill="currentColor">
                                                <path fillRule="evenodd" d="M18 10c0 3.866-3.582 7-8 7a8.841 8.841 0 01-4.083-.98L2 17l1.338-3.123C2.493 12.767 2 11.434 2 10c0-3.866 3.582-7 8-7s8 3.134 8 7zM7 9H5v2h2V9zm8 0h-2v2h2V9zM9 9h2v2H9V9z" clipRule="evenodd" />
                                            </svg>
                                            {chartComments.length > 0 && (
                                                <span className={styles.commentBadge}>{chartComments.length}</span>
                                            )}
                                        </button>
                                        <button
                                            className={styles.iconButton}
                                            onClick={() => removeChart(chart.id)}
                                            title="Delete chart"
                                        >
                                            <svg width="18" height="18" viewBox="0 0 20 20" fill="currentColor">
                                                <path fillRule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clipRule="evenodd" />
                                            </svg>
                                        </button>
                                    </div>
                                </div>

                                <div className={styles.chartContent}>
                                    <ChartRenderer config={chart} data={cleanData} />
                                </div>

                                {chartComments.length > 0 && (
                                    <div className={styles.commentsSection}>
                                        {chartComments.map(comment => (
                                            <div key={comment.id} className={styles.comment}>
                                                <div className={styles.commentAuthor}>{comment.author}</div>
                                                <div className={styles.commentText}>{comment.text}</div>
                                            </div>
                                        ))}
                                    </div>
                                )}

                                {selectedChartForComment === chart.id && (
                                    <div className={styles.commentInput}>
                                        <input
                                            type="text"
                                            placeholder="Add a comment..."
                                            value={commentText}
                                            onChange={(e) => setCommentText(e.target.value)}
                                            onKeyPress={(e) => e.key === 'Enter' && handleAddComment(chart.id)}
                                        />
                                        <button onClick={() => handleAddComment(chart.id)}>Post</button>
                                    </div>
                                )}
                            </div>
                        );
                    })}
                </div>
            )}

            {showBuilder && <ChartBuilder onClose={() => setShowBuilder(false)} />}
            {showCustomRequest && <CustomRequestModal onClose={() => setShowCustomRequest(false)} />}
        </div>
    );
}
