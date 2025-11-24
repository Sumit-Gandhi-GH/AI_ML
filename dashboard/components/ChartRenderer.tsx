'use client';

import React, { useMemo } from 'react';
import {
    BarChart,
    Bar,
    LineChart,
    Line,
    PieChart,
    Pie,
    AreaChart,
    Area,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    Legend,
    ResponsiveContainer,
    Cell,
} from 'recharts';
import { ChartConfig, DataRow } from '../store/useStore';
import { aggregateData } from '../utils/dataProcessing';

interface ChartRendererProps {
    config: ChartConfig;
    data: DataRow[];
}

const COLORS = ['#6366f1', '#8b5cf6', '#ec4899', '#f43f5e', '#10b981', '#14b8a6', '#f59e0b', '#ef4444'];

export default function ChartRenderer({ config, data }: ChartRendererProps) {
    const chartData = useMemo(() => {
        return aggregateData(data, config.xAxis, config.yAxis, config.aggregation);
    }, [data, config]);

    const renderChart = () => {
        switch (config.type) {
            case 'bar':
                return (
                    <ResponsiveContainer width="100%" height="100%">
                        <BarChart data={chartData}>
                            <CartesianGrid strokeDasharray="3 3" stroke="rgba(148, 163, 184, 0.1)" />
                            <XAxis
                                dataKey={config.xAxis}
                                stroke="#94a3b8"
                                style={{ fontSize: '0.75rem' }}
                            />
                            <YAxis
                                stroke="#94a3b8"
                                style={{ fontSize: '0.75rem' }}
                            />
                            <Tooltip
                                contentStyle={{
                                    background: '#1a1c24',
                                    border: '1px solid rgba(148, 163, 184, 0.2)',
                                    borderRadius: '8px',
                                    color: '#f8fafc',
                                }}
                            />
                            <Legend
                                wrapperStyle={{ fontSize: '0.875rem', color: '#cbd5e1' }}
                            />
                            <Bar dataKey={config.yAxis} fill="url(#barGradient)" radius={[8, 8, 0, 0]} />
                            <defs>
                                <linearGradient id="barGradient" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="0%" stopColor="#6366f1" />
                                    <stop offset="100%" stopColor="#8b5cf6" />
                                </linearGradient>
                            </defs>
                        </BarChart>
                    </ResponsiveContainer>
                );

            case 'line':
                return (
                    <ResponsiveContainer width="100%" height="100%">
                        <LineChart data={chartData}>
                            <CartesianGrid strokeDasharray="3 3" stroke="rgba(148, 163, 184, 0.1)" />
                            <XAxis
                                dataKey={config.xAxis}
                                stroke="#94a3b8"
                                style={{ fontSize: '0.75rem' }}
                            />
                            <YAxis
                                stroke="#94a3b8"
                                style={{ fontSize: '0.75rem' }}
                            />
                            <Tooltip
                                contentStyle={{
                                    background: '#1a1c24',
                                    border: '1px solid rgba(148, 163, 184, 0.2)',
                                    borderRadius: '8px',
                                    color: '#f8fafc',
                                }}
                            />
                            <Legend
                                wrapperStyle={{ fontSize: '0.875rem', color: '#cbd5e1' }}
                            />
                            <Line
                                type="monotone"
                                dataKey={config.yAxis}
                                stroke="#6366f1"
                                strokeWidth={3}
                                dot={{ fill: '#6366f1', r: 4 }}
                                activeDot={{ r: 6 }}
                            />
                        </LineChart>
                    </ResponsiveContainer>
                );

            case 'pie':
                return (
                    <ResponsiveContainer width="100%" height="100%">
                        <PieChart>
                            <Pie
                                data={chartData}
                                dataKey={config.yAxis}
                                nameKey={config.xAxis}
                                cx="50%"
                                cy="50%"
                                outerRadius={100}
                                label
                            >
                                {chartData.map((entry, index) => (
                                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                ))}
                            </Pie>
                            <Tooltip
                                contentStyle={{
                                    background: '#1a1c24',
                                    border: '1px solid rgba(148, 163, 184, 0.2)',
                                    borderRadius: '8px',
                                    color: '#f8fafc',
                                }}
                            />
                            <Legend
                                wrapperStyle={{ fontSize: '0.875rem', color: '#cbd5e1' }}
                            />
                        </PieChart>
                    </ResponsiveContainer>
                );

            case 'area':
                return (
                    <ResponsiveContainer width="100%" height="100%">
                        <AreaChart data={chartData}>
                            <CartesianGrid strokeDasharray="3 3" stroke="rgba(148, 163, 184, 0.1)" />
                            <XAxis
                                dataKey={config.xAxis}
                                stroke="#94a3b8"
                                style={{ fontSize: '0.75rem' }}
                            />
                            <YAxis
                                stroke="#94a3b8"
                                style={{ fontSize: '0.75rem' }}
                            />
                            <Tooltip
                                contentStyle={{
                                    background: '#1a1c24',
                                    border: '1px solid rgba(148, 163, 184, 0.2)',
                                    borderRadius: '8px',
                                    color: '#f8fafc',
                                }}
                            />
                            <Legend
                                wrapperStyle={{ fontSize: '0.875rem', color: '#cbd5e1' }}
                            />
                            <Area
                                type="monotone"
                                dataKey={config.yAxis}
                                stroke="#6366f1"
                                fill="url(#areaGradient)"
                                strokeWidth={2}
                            />
                            <defs>
                                <linearGradient id="areaGradient" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="0%" stopColor="#6366f1" stopOpacity={0.8} />
                                    <stop offset="100%" stopColor="#8b5cf6" stopOpacity={0.1} />
                                </linearGradient>
                            </defs>
                        </AreaChart>
                    </ResponsiveContainer>
                );

            default:
                return null;
        }
    };

    return <>{renderChart()}</>;
}
