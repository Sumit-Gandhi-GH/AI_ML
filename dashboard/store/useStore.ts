import { create } from 'zustand';

export interface DataRow {
  [key: string]: string | number;
}

export interface ChartConfig {
  id: string;
  type: 'bar' | 'line' | 'pie' | 'area';
  xAxis: string;
  yAxis: string;
  aggregation: 'sum' | 'count' | 'avg' | 'min' | 'max';
  title: string;
}

export interface Comment {
  id: string;
  chartId: string;
  text: string;
  author: string;
  timestamp: number;
}

export interface DataQualityIssue {
  column: string;
  type: 'missing' | 'type_mismatch' | 'outlier';
  count: number;
  percentage: number;
}

export interface DataQualityReport {
  totalRows: number;
  totalColumns: number;
  issues: DataQualityIssue[];
  completeness: number;
}

interface DashboardState {
  // Data
  rawData: DataRow[];
  cleanData: DataRow[];
  columns: string[];
  dataQualityReport: DataQualityReport | null;
  
  // Charts
  charts: ChartConfig[];
  selectedChartId: string | null;
  
  // Comments
  comments: Comment[];
  
  // Filters
  activeFilters: Record<string, any>;
  
  // Actions
  setRawData: (data: DataRow[]) => void;
  setCleanData: (data: DataRow[]) => void;
  setColumns: (columns: string[]) => void;
  setDataQualityReport: (report: DataQualityReport) => void;
  
  addChart: (chart: ChartConfig) => void;
  removeChart: (chartId: string) => void;
  updateChart: (chartId: string, updates: Partial<ChartConfig>) => void;
  setSelectedChartId: (chartId: string | null) => void;
  
  addComment: (comment: Comment) => void;
  removeComment: (commentId: string) => void;
  
  setActiveFilters: (filters: Record<string, any>) => void;
  clearFilters: () => void;
  
  reset: () => void;
}

const initialState = {
  rawData: [],
  cleanData: [],
  columns: [],
  dataQualityReport: null,
  charts: [],
  selectedChartId: null,
  comments: [],
  activeFilters: {},
};

export const useDashboardStore = create<DashboardState>((set) => ({
  ...initialState,
  
  setRawData: (data) => set({ rawData: data }),
  setCleanData: (data) => set({ cleanData: data }),
  setColumns: (columns) => set({ columns }),
  setDataQualityReport: (report) => set({ dataQualityReport: report }),
  
  addChart: (chart) => set((state) => ({ 
    charts: [...state.charts, chart] 
  })),
  
  removeChart: (chartId) => set((state) => ({ 
    charts: state.charts.filter(c => c.id !== chartId),
    comments: state.comments.filter(c => c.chartId !== chartId),
  })),
  
  updateChart: (chartId, updates) => set((state) => ({
    charts: state.charts.map(c => 
      c.id === chartId ? { ...c, ...updates } : c
    ),
  })),
  
  setSelectedChartId: (chartId) => set({ selectedChartId: chartId }),
  
  addComment: (comment) => set((state) => ({ 
    comments: [...state.comments, comment] 
  })),
  
  removeComment: (commentId) => set((state) => ({ 
    comments: state.comments.filter(c => c.id !== commentId) 
  })),
  
  setActiveFilters: (filters) => set({ activeFilters: filters }),
  clearFilters: () => set({ activeFilters: {} }),
  
  reset: () => set(initialState),
}));
