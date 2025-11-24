'use client';

import React, { useState } from 'react';
import { useDashboardStore } from '../store/useStore';
import styles from './ChartBuilder.module.css';

interface ChartBuilderProps {
    onClose: () => void;
}

export default function ChartBuilder({ onClose }: ChartBuilderProps) {
    const { columns, addChart } = useDashboardStore();
    const [chartType, setChartType] = useState<'bar' | 'line' | 'pie' | 'area'>('bar');
    const [xAxis, setXAxis] = useState('');
    const [yAxis, setYAxis] = useState('');
    const [aggregation, setAggregation] = useState<'sum' | 'count' | 'avg' | 'min' | 'max'>('sum');
    const [title, setTitle] = useState('');

    const handleCreate = () => {
        if (xAxis && yAxis && title) {
            addChart({
                id: Date.now().toString(),
                type: chartType,
                xAxis,
                yAxis,
                aggregation,
                title,
            });
            onClose();
        }
    };

    return (
        <div className={styles.overlay} onClick={onClose}>
            <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
                <div className={styles.header}>
                    <h2>Create New Chart</h2>
                    <button className={styles.closeButton} onClick={onClose}>
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                            <path d="M6 18L18 6M6 6l12 12" strokeWidth="2" strokeLinecap="round" />
                        </svg>
                    </button>
                </div>

                <div className={styles.content}>
                    <div className={styles.field}>
                        <label>Chart Title</label>
                        <input
                            type="text"
                            placeholder="e.g., Sales by Region"
                            value={title}
                            onChange={(e) => setTitle(e.target.value)}
                        />
                    </div>

                    <div className={styles.field}>
                        <label>Chart Type</label>
                        <div className={styles.typeGrid}>
                            {['bar', 'line', 'pie', 'area'].map((type) => (
                                <button
                                    key={type}
                                    className={`${styles.typeButton} ${chartType === type ? styles.active : ''}`}
                                    onClick={() => setChartType(type as any)}
                                >
                                    {type.charAt(0).toUpperCase() + type.slice(1)}
                                </button>
                            ))}
                        </div>
                    </div>

                    <div className={styles.field}>
                        <label>X-Axis (Category)</label>
                        <select value={xAxis} onChange={(e) => setXAxis(e.target.value)}>
                            <option value="">Select column...</option>
                            {columns.map((col) => (
                                <option key={col} value={col}>{col}</option>
                            ))}
                        </select>
                    </div>

                    <div className={styles.field}>
                        <label>Y-Axis (Value)</label>
                        <select value={yAxis} onChange={(e) => setYAxis(e.target.value)}>
                            <option value="">Select column...</option>
                            {columns.map((col) => (
                                <option key={col} value={col}>{col}</option>
                            ))}
                        </select>
                    </div>

                    <div className={styles.field}>
                        <label>Aggregation</label>
                        <select value={aggregation} onChange={(e) => setAggregation(e.target.value as any)}>
                            <option value="sum">Sum</option>
                            <option value="count">Count</option>
                            <option value="avg">Average</option>
                            <option value="min">Minimum</option>
                            <option value="max">Maximum</option>
                        </select>
                    </div>
                </div>

                <div className={styles.footer}>
                    <button className={styles.cancelButton} onClick={onClose}>
                        Cancel
                    </button>
                    <button
                        className={styles.createButton}
                        onClick={handleCreate}
                        disabled={!xAxis || !yAxis || !title}
                    >
                        Create Chart
                    </button>
                </div>
            </div>
        </div>
    );
}
