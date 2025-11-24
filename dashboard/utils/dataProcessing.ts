import { DataRow, DataQualityReport, DataQualityIssue } from '../store/useStore';

export function analyzeDataQuality(data: DataRow[]): DataQualityReport {
    if (data.length === 0) {
        return {
            totalRows: 0,
            totalColumns: 0,
            issues: [],
            completeness: 100,
        };
    }

    const columns = Object.keys(data[0]);
    const issues: DataQualityIssue[] = [];

    // Check for missing values
    columns.forEach(column => {
        const missingCount = data.filter(row =>
            row[column] === null ||
            row[column] === undefined ||
            row[column] === '' ||
            (typeof row[column] === 'string' && row[column].trim() === '')
        ).length;

        if (missingCount > 0) {
            issues.push({
                column,
                type: 'missing',
                count: missingCount,
                percentage: (missingCount / data.length) * 100,
            });
        }
    });

    // Check for type consistency
    columns.forEach(column => {
        const types = new Set<string>();
        data.forEach(row => {
            if (row[column] !== null && row[column] !== undefined && row[column] !== '') {
                types.add(typeof row[column]);
            }
        });

        if (types.size > 1) {
            issues.push({
                column,
                type: 'type_mismatch',
                count: data.length,
                percentage: 100,
            });
        }
    });

    // Calculate completeness
    const totalCells = data.length * columns.length;
    const missingCells = issues
        .filter(i => i.type === 'missing')
        .reduce((sum, i) => sum + i.count, 0);
    const completeness = ((totalCells - missingCells) / totalCells) * 100;

    return {
        totalRows: data.length,
        totalColumns: columns.length,
        issues,
        completeness,
    };
}

export function cleanData(
    data: DataRow[],
    strategy: 'drop' | 'impute' = 'drop'
): DataRow[] {
    if (strategy === 'drop') {
        // Remove rows with any missing values
        return data.filter(row => {
            return Object.values(row).every(value =>
                value !== null &&
                value !== undefined &&
                value !== '' &&
                !(typeof value === 'string' && value.trim() === '')
            );
        });
    } else {
        // Impute missing values with column mean/mode
        const columns = Object.keys(data[0]);
        const cleanedData = [...data];

        columns.forEach(column => {
            const values = data
                .map(row => row[column])
                .filter(v => v !== null && v !== undefined && v !== '');

            if (values.length === 0) return;

            // Check if numeric
            const isNumeric = values.every(v => !isNaN(Number(v)));

            let fillValue: any;
            if (isNumeric) {
                // Use mean for numeric columns
                const sum = values.reduce((acc, v) => acc + Number(v), 0);
                fillValue = sum / values.length;
            } else {
                // Use mode for categorical columns
                const counts: Record<string, number> = {};
                values.forEach(v => {
                    const key = String(v);
                    counts[key] = (counts[key] || 0) + 1;
                });
                fillValue = Object.keys(counts).reduce((a, b) =>
                    counts[a] > counts[b] ? a : b
                );
            }

            // Fill missing values
            cleanedData.forEach(row => {
                if (
                    row[column] === null ||
                    row[column] === undefined ||
                    row[column] === '' ||
                    (typeof row[column] === 'string' && row[column].trim() === '')
                ) {
                    row[column] = fillValue;
                }
            });
        });

        return cleanedData;
    }
}

export function detectColumnType(data: DataRow[], column: string): 'number' | 'string' | 'date' {
    const sample = data
        .map(row => row[column])
        .filter(v => v !== null && v !== undefined && v !== '')
        .slice(0, 100);

    if (sample.length === 0) return 'string';

    // Check if numeric
    const numericCount = sample.filter(v => !isNaN(Number(v))).length;
    if (numericCount / sample.length > 0.8) return 'number';

    // Check if date
    const dateCount = sample.filter(v => !isNaN(Date.parse(String(v)))).length;
    if (dateCount / sample.length > 0.8) return 'date';

    return 'string';
}

export function aggregateData(
    data: DataRow[],
    groupBy: string,
    valueColumn: string,
    aggregation: 'sum' | 'count' | 'avg' | 'min' | 'max'
): DataRow[] {
    const groups: Record<string, number[]> = {};

    data.forEach(row => {
        const key = String(row[groupBy]);
        if (!groups[key]) groups[key] = [];

        if (aggregation === 'count') {
            groups[key].push(1);
        } else {
            const value = Number(row[valueColumn]);
            if (!isNaN(value)) {
                groups[key].push(value);
            }
        }
    });

    return Object.entries(groups).map(([key, values]) => {
        let aggregatedValue: number;

        switch (aggregation) {
            case 'sum':
            case 'count':
                aggregatedValue = values.reduce((a, b) => a + b, 0);
                break;
            case 'avg':
                aggregatedValue = values.reduce((a, b) => a + b, 0) / values.length;
                break;
            case 'min':
                aggregatedValue = Math.min(...values);
                break;
            case 'max':
                aggregatedValue = Math.max(...values);
                break;
        }

        return {
            [groupBy]: key,
            [valueColumn]: aggregatedValue,
        };
    });
}
