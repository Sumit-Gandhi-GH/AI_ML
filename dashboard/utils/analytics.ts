import { DataRow } from '../store/useStore';

export interface DataInsight {
    type: 'trend' | 'correlation' | 'outlier' | 'distribution' | 'summary';
    title: string;
    description: string;
    confidence: number;
    data?: any;
}

export function generateAutomatedInsights(data: DataRow[], columns: string[]): DataInsight[] {
    const insights: DataInsight[] = [];

    if (data.length === 0) return insights;

    // Identify numeric and categorical columns
    const numericColumns: string[] = [];
    const categoricalColumns: string[] = [];

    columns.forEach(col => {
        const sample = data.slice(0, 100).map(row => row[col]);
        const numericCount = sample.filter(v => v !== null && !isNaN(Number(v))).length;

        if (numericCount / sample.length > 0.8) {
            numericColumns.push(col);
        } else {
            categoricalColumns.push(col);
        }
    });

    // Summary insight
    insights.push({
        type: 'summary',
        title: 'Dataset Overview',
        description: `Your dataset contains ${data.length.toLocaleString()} records with ${columns.length} columns. ${numericColumns.length} numeric columns and ${categoricalColumns.length} categorical columns detected.`,
        confidence: 1.0,
    });

    // Analyze numeric columns for trends
    numericColumns.forEach(col => {
        const values = data.map(row => Number(row[col])).filter(v => !isNaN(v));
        if (values.length === 0) return;

        const avg = values.reduce((a, b) => a + b, 0) / values.length;
        const max = Math.max(...values);
        const min = Math.min(...values);
        const range = max - min;

        // Check for outliers (simple IQR method)
        const sorted = [...values].sort((a, b) => a - b);
        const q1 = sorted[Math.floor(sorted.length * 0.25)];
        const q3 = sorted[Math.floor(sorted.length * 0.75)];
        const iqr = q3 - q1;
        const outliers = values.filter(v => v < q1 - 1.5 * iqr || v > q3 + 1.5 * iqr);

        if (outliers.length > 0) {
            insights.push({
                type: 'outlier',
                title: `Outliers Detected in ${col}`,
                description: `Found ${outliers.length} potential outliers (${((outliers.length / values.length) * 100).toFixed(1)}% of data). Average: ${avg.toFixed(2)}, Range: ${min.toFixed(2)} - ${max.toFixed(2)}`,
                confidence: 0.8,
                data: { column: col, count: outliers.length },
            });
        }

        // Trend analysis (if data appears sequential)
        if (values.length > 10) {
            const firstHalf = values.slice(0, Math.floor(values.length / 2));
            const secondHalf = values.slice(Math.floor(values.length / 2));
            const firstAvg = firstHalf.reduce((a, b) => a + b, 0) / firstHalf.length;
            const secondAvg = secondHalf.reduce((a, b) => a + b, 0) / secondHalf.length;
            const change = ((secondAvg - firstAvg) / firstAvg) * 100;

            if (Math.abs(change) > 10) {
                insights.push({
                    type: 'trend',
                    title: `${change > 0 ? 'Increasing' : 'Decreasing'} Trend in ${col}`,
                    description: `${col} shows a ${Math.abs(change).toFixed(1)}% ${change > 0 ? 'increase' : 'decrease'} from first half to second half of the dataset.`,
                    confidence: 0.7,
                    data: { column: col, change },
                });
            }
        }
    });

    // Analyze categorical distributions
    categoricalColumns.forEach(col => {
        const valueCounts: Record<string, number> = {};
        data.forEach(row => {
            const val = String(row[col] || 'Unknown');
            valueCounts[val] = (valueCounts[val] || 0) + 1;
        });

        const uniqueCount = Object.keys(valueCounts).length;
        const topValue = Object.entries(valueCounts).sort((a, b) => b[1] - a[1])[0];

        if (uniqueCount <= 10 && topValue) {
            const percentage = (topValue[1] / data.length) * 100;
            insights.push({
                type: 'distribution',
                title: `Distribution in ${col}`,
                description: `${col} has ${uniqueCount} unique values. Most common: "${topValue[0]}" (${percentage.toFixed(1)}%, ${topValue[1]} records)`,
                confidence: 0.9,
                data: { column: col, topValue: topValue[0], count: topValue[1] },
            });
        }
    });

    // Correlation insights (simple)
    if (numericColumns.length >= 2) {
        for (let i = 0; i < Math.min(numericColumns.length, 3); i++) {
            for (let j = i + 1; j < Math.min(numericColumns.length, 3); j++) {
                const col1 = numericColumns[i];
                const col2 = numericColumns[j];

                insights.push({
                    type: 'correlation',
                    title: `Relationship: ${col1} vs ${col2}`,
                    description: `Consider analyzing the relationship between ${col1} and ${col2} using a scatter plot or correlation analysis.`,
                    confidence: 0.6,
                    data: { column1: col1, column2: col2 },
                });
            }
        }
    }

    return insights.sort((a, b) => b.confidence - a.confidence).slice(0, 8);
}

export function analyzeBusinessQuery(query: string, data: DataRow[], columns: string[]): string {
    const lowerQuery = query.toLowerCase();

    // Sales-related queries
    if (lowerQuery.includes('sales') || lowerQuery.includes('revenue')) {
        const salesColumns = columns.filter(col =>
            col.toLowerCase().includes('sales') ||
            col.toLowerCase().includes('revenue') ||
            col.toLowerCase().includes('amount')
        );

        if (salesColumns.length > 0) {
            const salesCol = salesColumns[0];
            const values = data.map(row => Number(row[salesCol])).filter(v => !isNaN(v));
            const total = values.reduce((a, b) => a + b, 0);
            const avg = total / values.length;
            const max = Math.max(...values);

            return `**Sales Analysis:**\n\n` +
                `• Total Sales: ${total.toLocaleString()}\n` +
                `• Average: ${avg.toFixed(2)}\n` +
                `• Peak: ${max.toLocaleString()}\n` +
                `• Transactions: ${values.length}\n\n` +
                `Consider visualizing this with a bar chart grouped by region or time period.`;
        }
    }

    // Role/People queries
    if (lowerQuery.includes('role') || lowerQuery.includes('employee') || lowerQuery.includes('people')) {
        const roleColumns = columns.filter(col =>
            col.toLowerCase().includes('role') ||
            col.toLowerCase().includes('position') ||
            col.toLowerCase().includes('title') ||
            col.toLowerCase().includes('department')
        );

        if (roleColumns.length > 0) {
            const roleCol = roleColumns[0];
            const roleCounts: Record<string, number> = {};
            data.forEach(row => {
                const role = String(row[roleCol] || 'Unknown');
                roleCounts[role] = (roleCounts[role] || 0) + 1;
            });

            const topRoles = Object.entries(roleCounts)
                .sort((a, b) => b[1] - a[1])
                .slice(0, 5);

            return `**Role Distribution:**\n\n` +
                topRoles.map(([role, count]) => `• ${role}: ${count} (${((count / data.length) * 100).toFixed(1)}%)`).join('\n') +
                `\n\nTotal unique roles: ${Object.keys(roleCounts).length}`;
        }
    }

    // Top/Bottom performers
    if (lowerQuery.includes('top') || lowerQuery.includes('best') || lowerQuery.includes('highest')) {
        const numericCols = columns.filter(col => {
            const sample = data.slice(0, 10).map(row => row[col]);
            return sample.every(v => !isNaN(Number(v)));
        });

        if (numericCols.length > 0) {
            const valueCol = numericCols[0];
            const sorted = [...data].sort((a, b) => Number(b[valueCol]) - Number(a[valueCol]));
            const top5 = sorted.slice(0, 5);

            const categoryCol = columns.find(col => col !== valueCol) || columns[0];

            return `**Top Performers (by ${valueCol}):**\n\n` +
                top5.map((row, i) => `${i + 1}. ${row[categoryCol]}: ${Number(row[valueCol]).toLocaleString()}`).join('\n');
        }
    }

    // Trend analysis
    if (lowerQuery.includes('trend') || lowerQuery.includes('over time') || lowerQuery.includes('growth')) {
        return `**Trend Analysis:**\n\n` +
            `To analyze trends, I recommend:\n` +
            `• Create a line chart with time on X-axis\n` +
            `• Look for seasonal patterns\n` +
            `• Calculate growth rates between periods\n` +
            `• Identify any anomalies or spikes\n\n` +
            `Available time-related columns: ${columns.filter(c => c.toLowerCase().includes('date') || c.toLowerCase().includes('time')).join(', ') || 'None detected'}`;
    }

    // Comparison queries
    if (lowerQuery.includes('compare') || lowerQuery.includes('vs') || lowerQuery.includes('versus')) {
        return `**Comparison Analysis:**\n\n` +
            `For effective comparisons:\n` +
            `• Use bar charts for category comparisons\n` +
            `• Use line charts for time-based comparisons\n` +
            `• Consider grouping by: ${columns.slice(0, 3).join(', ')}\n` +
            `• Measure using: ${columns.filter(c => !isNaN(Number(data[0]?.[c]))).slice(0, 2).join(', ')}`;
    }

    // Summary/Overview
    if (lowerQuery.includes('summary') || lowerQuery.includes('overview') || lowerQuery.includes('insight')) {
        const insights = generateAutomatedInsights(data, columns);
        return `**Key Insights:**\n\n` +
            insights.slice(0, 5).map(i => `• ${i.title}: ${i.description}`).join('\n\n');
    }

    // Default intelligent response
    return `**Analysis Suggestion:**\n\n` +
        `Based on your data structure, here are some analyses you can perform:\n\n` +
        `📊 **Available Columns:** ${columns.join(', ')}\n\n` +
        `💡 **Suggested Questions:**\n` +
        `• "What are the top performers?"\n` +
        `• "Show me sales trends"\n` +
        `• "What insights can you find?"\n` +
        `• "Compare categories"\n` +
        `• "Analyze distribution of [column name]"`;
}
