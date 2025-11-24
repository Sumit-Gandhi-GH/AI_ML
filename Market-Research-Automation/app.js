// Application State
const state = {
    csvData: null,
    csvFile: null,
    selectedLLM: 'gemini',
    apiKey: '',
    systemInstructions: '',
    researchPrompt: '',
    results: [],
    isProcessing: false
};

// DOM Elements
const elements = {
    uploadArea: null,
    csvInput: null,
    filePreview: null,
    fileName: null,
    fileStats: null,
    removeFile: null,
    previewTable: null,
    previewHeader: null,
    previewBody: null,
    apiKeyInput: null,
    systemInstructionsInput: null,
    researchPromptInput: null,
    startResearchBtn: null,
    resultsEmpty: null,
    resultsContainer: null,
    totalCompanies: null,
    completedCount: null,
    progressPercent: null,
    progressFill: null,
    resultsTbody: null,
    exportCsvBtn: null,
    exportJsonBtn: null
};

// Initialize Application
document.addEventListener('DOMContentLoaded', () => {
    initializeElements();
    setupEventListeners();
    loadSavedSettings();
});

function initializeElements() {
    elements.uploadArea = document.getElementById('upload-area');
    elements.csvInput = document.getElementById('csv-input');
    elements.filePreview = document.getElementById('file-preview');
    elements.fileName = document.getElementById('file-name');
    elements.fileStats = document.getElementById('file-stats');
    elements.removeFile = document.getElementById('remove-file');
    elements.previewTable = document.getElementById('preview-table');
    elements.previewHeader = document.getElementById('preview-header');
    elements.previewBody = document.getElementById('preview-body');
    elements.apiKeyInput = document.getElementById('api-key');
    elements.systemInstructionsInput = document.getElementById('system-instructions');
    elements.researchPromptInput = document.getElementById('research-prompt');
    elements.startResearchBtn = document.getElementById('start-research');
    elements.resultsEmpty = document.getElementById('results-empty');
    elements.resultsContainer = document.getElementById('results-container');
    elements.totalCompanies = document.getElementById('total-companies');
    elements.completedCount = document.getElementById('completed-count');
    elements.progressPercent = document.getElementById('progress-percent');
    elements.progressFill = document.getElementById('progress-fill');
    elements.resultsTbody = document.getElementById('results-tbody');
    elements.exportCsvBtn = document.getElementById('export-csv');
    elements.exportJsonBtn = document.getElementById('export-json');
}

function setupEventListeners() {
    // Navigation
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.addEventListener('click', () => switchSection(btn.dataset.section));
    });

    // File Upload
    elements.uploadArea.addEventListener('click', () => elements.csvInput.click());
    elements.uploadArea.addEventListener('dragover', handleDragOver);
    elements.uploadArea.addEventListener('dragleave', handleDragLeave);
    elements.uploadArea.addEventListener('drop', handleDrop);
    elements.csvInput.addEventListener('change', handleFileSelect);
    elements.removeFile.addEventListener('click', (e) => {
        e.stopPropagation();
        clearFile();
    });

    // LLM Selection
    document.querySelectorAll('input[name="llm"]').forEach(radio => {
        radio.addEventListener('change', (e) => {
            state.selectedLLM = e.target.value;
            saveSettings();
        });
    });

    // Configuration
    elements.apiKeyInput.addEventListener('input', (e) => {
        state.apiKey = e.target.value;
        saveSettings();
    });

    elements.systemInstructionsInput.addEventListener('input', (e) => {
        state.systemInstructions = e.target.value;
        saveSettings();
    });

    elements.researchPromptInput.addEventListener('input', (e) => {
        state.researchPrompt = e.target.value;
        saveSettings();
    });

    // Research
    elements.startResearchBtn.addEventListener('click', startResearch);

    // Export
    elements.exportCsvBtn.addEventListener('click', exportToCSV);
    elements.exportJsonBtn.addEventListener('click', exportToJSON);
}

// Navigation
function switchSection(sectionName) {
    // Update nav buttons
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.section === sectionName);
    });

    // Update sections
    document.querySelectorAll('.section').forEach(section => {
        section.classList.toggle('active', section.id === `${sectionName}-section`);
    });
}

// File Upload Handlers
function handleDragOver(e) {
    e.preventDefault();
    elements.uploadArea.classList.add('drag-over');
}

function handleDragLeave(e) {
    e.preventDefault();
    elements.uploadArea.classList.remove('drag-over');
}

function handleDrop(e) {
    e.preventDefault();
    elements.uploadArea.classList.remove('drag-over');
    
    const files = e.dataTransfer.files;
    if (files.length > 0 && files[0].name.endsWith('.csv')) {
        processFile(files[0]);
    } else {
        alert('Please upload a valid CSV file');
    }
}

function handleFileSelect(e) {
    const file = e.target.files[0];
    if (file) {
        processFile(file);
    }
}

function processFile(file) {
    state.csvFile = file;
    
    const reader = new FileReader();
    reader.onload = (e) => {
        const text = e.target.result;
        parseCSV(text);
        displayFilePreview(file);
    };
    reader.readAsText(file);
}

function parseCSV(text) {
    const lines = text.trim().split('\n');
    const headers = lines[0].split(',').map(h => h.trim());
    
    const data = [];
    for (let i = 1; i < lines.length; i++) {
        const values = lines[i].split(',').map(v => v.trim());
        const row = {};
        headers.forEach((header, index) => {
            row[header] = values[index] || '';
        });
        data.push(row);
    }
    
    state.csvData = { headers, data };
}

function displayFilePreview(file) {
    // Show preview container
    elements.filePreview.style.display = 'block';
    
    // Update file info
    elements.fileName.textContent = file.name;
    const sizeKB = (file.size / 1024).toFixed(2);
    elements.fileStats.textContent = `${state.csvData.data.length} companies • ${sizeKB} KB`;
    
    // Update preview table
    elements.previewHeader.innerHTML = '';
    elements.previewBody.innerHTML = '';
    
    // Add headers
    const headerRow = document.createElement('tr');
    state.csvData.headers.forEach(header => {
        const th = document.createElement('th');
        th.textContent = header;
        headerRow.appendChild(th);
    });
    elements.previewHeader.appendChild(headerRow);
    
    // Add first 5 rows
    const previewRows = state.csvData.data.slice(0, 5);
    previewRows.forEach(row => {
        const tr = document.createElement('tr');
        state.csvData.headers.forEach(header => {
            const td = document.createElement('td');
            td.textContent = row[header] || '-';
            tr.appendChild(td);
        });
        elements.previewBody.appendChild(tr);
    });
}

function clearFile() {
    state.csvFile = null;
    state.csvData = null;
    elements.csvInput.value = '';
    elements.filePreview.style.display = 'none';
}

// Settings Management
function saveSettings() {
    const settings = {
        selectedLLM: state.selectedLLM,
        apiKey: state.apiKey,
        systemInstructions: state.systemInstructions,
        researchPrompt: state.researchPrompt
    };
    localStorage.setItem('marketResearchSettings', JSON.stringify(settings));
}

function loadSavedSettings() {
    const saved = localStorage.getItem('marketResearchSettings');
    if (saved) {
        const settings = JSON.parse(saved);
        
        if (settings.selectedLLM) {
            state.selectedLLM = settings.selectedLLM;
            document.querySelector(`input[name="llm"][value="${settings.selectedLLM}"]`).checked = true;
        }
        
        if (settings.apiKey) {
            state.apiKey = settings.apiKey;
            elements.apiKeyInput.value = settings.apiKey;
        }
        
        if (settings.systemInstructions) {
            state.systemInstructions = settings.systemInstructions;
            elements.systemInstructionsInput.value = settings.systemInstructions;
        }
        
        if (settings.researchPrompt) {
            state.researchPrompt = settings.researchPrompt;
            elements.researchPromptInput.value = settings.researchPrompt;
        }
    }
}

// Research Execution
async function startResearch() {
    // Validation
    if (!state.csvData) {
        alert('Please upload a CSV file first');
        switchSection('upload');
        return;
    }
    
    if (!state.apiKey) {
        alert('Please enter your API key');
        return;
    }
    
    if (!state.researchPrompt) {
        alert('Please enter a research prompt');
        return;
    }
    
    // Initialize results
    state.isProcessing = true;
    state.results = state.csvData.data.map(row => ({
        company: row[state.csvData.headers[0]] || 'Unknown',
        status: 'pending',
        data: null,
        error: null
    }));
    
    // Switch to results view
    switchSection('results');
    showResultsContainer();
    updateResultsDisplay();
    
    // Process companies
    elements.startResearchBtn.disabled = true;
    elements.startResearchBtn.innerHTML = `
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="10"/>
        </svg>
        Processing...
    `;
    
    // Simulate research (in production, this would call actual LLM APIs)
    await processCompanies();
    
    elements.startResearchBtn.disabled = false;
    elements.startResearchBtn.innerHTML = `
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polygon points="5 3 19 12 5 21 5 3"/>
        </svg>
        Start Research
    `;
    state.isProcessing = false;
}

async function processCompanies() {
    for (let i = 0; i < state.results.length; i++) {
        state.results[i].status = 'processing';
        updateResultsDisplay();
        
        // Simulate API call delay
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        // Simulate research results
        state.results[i].status = 'completed';
        state.results[i].data = generateMockData(state.results[i].company);
        
        updateResultsDisplay();
    }
}

function generateMockData(companyName) {
    const revenues = ['$1M - $10M', '$10M - $50M', '$50M - $100M', '$100M - $500M', '$500M+'];
    const employees = ['1-10', '11-50', '51-200', '201-500', '501-1000', '1000+'];
    const industries = ['Technology', 'Finance', 'Healthcare', 'Retail', 'Manufacturing', 'Services'];
    const locations = ['San Francisco, CA, USA', 'New York, NY, USA', 'London, UK', 'Singapore', 'Toronto, Canada'];
    
    return {
        annual_revenue: revenues[Math.floor(Math.random() * revenues.length)],
        employee_count: employees[Math.floor(Math.random() * employees.length)],
        website: `https://www.${companyName.toLowerCase().replace(/\s+/g, '')}.com`,
        email_domain: `${companyName.toLowerCase().replace(/\s+/g, '')}.com`,
        industry: industries[Math.floor(Math.random() * industries.length)],
        sub_industry: 'Software & Services',
        headquarters_location: locations[Math.floor(Math.random() * locations.length)],
        linkedin_url: `https://www.linkedin.com/company/${companyName.toLowerCase().replace(/\s+/g, '-')}`
    };
}

function showResultsContainer() {
    elements.resultsEmpty.style.display = 'none';
    elements.resultsContainer.style.display = 'block';
}

function updateResultsDisplay() {
    // Update stats
    const total = state.results.length;
    const completed = state.results.filter(r => r.status === 'completed').length;
    const progress = total > 0 ? Math.round((completed / total) * 100) : 0;
    
    elements.totalCompanies.textContent = total;
    elements.completedCount.textContent = completed;
    elements.progressPercent.textContent = `${progress}%`;
    elements.progressFill.style.width = `${progress}%`;
    
    // Update table
    elements.resultsTbody.innerHTML = '';
    state.results.forEach(result => {
        const tr = document.createElement('tr');
        
        const statusBadge = `
            <span class="status-badge ${result.status}">
                ${result.status.charAt(0).toUpperCase() + result.status.slice(1)}
            </span>
        `;
        
        if (result.data) {
            tr.innerHTML = `
                <td>${result.company}</td>
                <td>${result.data.annual_revenue}</td>
                <td>${result.data.employee_count}</td>
                <td><a href="${result.data.website}" target="_blank" style="color: var(--primary-500);">${result.data.website}</a></td>
                <td>${result.data.industry}</td>
                <td>${result.data.headquarters_location}</td>
                <td>${statusBadge}</td>
            `;
        } else {
            tr.innerHTML = `
                <td>${result.company}</td>
                <td>-</td>
                <td>-</td>
                <td>-</td>
                <td>-</td>
                <td>-</td>
                <td>${statusBadge}</td>
            `;
        }
        
        elements.resultsTbody.appendChild(tr);
    });
}

// Export Functions
function exportToCSV() {
    const headers = ['Company', 'Annual Revenue', 'Employee Count', 'Website', 'Email Domain', 
                     'Industry', 'Sub-Industry', 'Headquarters Location', 'LinkedIn URL'];
    
    const rows = state.results
        .filter(r => r.data)
        .map(r => [
            r.company,
            r.data.annual_revenue,
            r.data.employee_count,
            r.data.website,
            r.data.email_domain,
            r.data.industry,
            r.data.sub_industry,
            r.data.headquarters_location,
            r.data.linkedin_url
        ]);
    
    const csv = [headers, ...rows]
        .map(row => row.map(cell => `"${cell}"`).join(','))
        .join('\n');
    
    downloadFile(csv, 'market-research-results.csv', 'text/csv');
}

function exportToJSON() {
    const data = state.results
        .filter(r => r.data)
        .map(r => ({
            company: r.company,
            ...r.data
        }));
    
    const json = JSON.stringify(data, null, 2);
    downloadFile(json, 'market-research-results.json', 'application/json');
}

function downloadFile(content, filename, mimeType) {
    const blob = new Blob([content], { type: mimeType });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}
