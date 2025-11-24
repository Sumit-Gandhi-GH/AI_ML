// Global state
let state = {
    sessionId: null,
    columns: [],
    selectedTextColumns: [],
    selectedMetadataColumns: [],
    provider: 'sentence-transformers',
    apiKey: null,
    model: null,
    // Comparison state
    jobIdA: null,
    jobIdB: null,
    tempJobIdB: null,
    columnsB: []
};

// DOM Elements
const tabs = document.querySelectorAll('.tab-btn');
const tabContents = document.querySelectorAll('.tab-content');
const fileInput = document.getElementById('csv-file');
const fileUploadArea = document.getElementById('file-upload-area');
const fileInfo = document.getElementById('file-info');
const fileName = document.getElementById('file-name');
const rowCount = document.getElementById('row-count');
const configSection = document.getElementById('config-section');
const providerSelect = document.getElementById('provider');
const apiKeyGroup = document.getElementById('api-key-group');
const apiKeyInput = document.getElementById('api-key');
const modelGroup = document.getElementById('model-group');
const modelInput = document.getElementById('model');
const modelHint = document.getElementById('model-hint');
const textColumnsDiv = document.getElementById('text-columns');
const metadataColumnsDiv = document.getElementById('metadata-columns');
const combineCheckbox = document.getElementById('combine-columns');
const generateBtn = document.getElementById('generate-btn');
const progressSection = document.getElementById('progress-section');
const progressFill = document.getElementById('progress-fill');
const progressText = document.getElementById('progress-text');
const resultsSection = document.getElementById('results-section');
const embeddingCount = document.getElementById('embedding-count');
const embeddingDim = document.getElementById('embedding-dim');
const outputFormatSelect = document.getElementById('output-format');
const downloadBtn = document.getElementById('download-btn');
const resetBtn = document.getElementById('reset-btn');
const previewSection = document.getElementById('preview-section');
const previewBody = document.getElementById('preview-body');
const alertDiv = document.getElementById('alert');
const clusterBtn = document.getElementById('cluster-btn');
const nClustersInput = document.getElementById('n-clusters');
const clusterResults = document.getElementById('cluster-results');
const clusterBody = document.getElementById('cluster-body');

// Comparison Elements
const sourceAStatus = document.getElementById('source-a-status');
const fileInputB = document.getElementById('csv-file-b');
const sourceBUpload = document.getElementById('source-b-upload');
const sourceBConfig = document.getElementById('source-b-config');
const textColumnBSelect = document.getElementById('text-column-b');
const generateBtnB = document.getElementById('generate-btn-b');
const sourceBStatus = document.getElementById('source-b-status');
const thresholdInput = document.getElementById('similarity-threshold');
const thresholdValue = document.getElementById('threshold-value');
const compareBtn = document.getElementById('compare-btn');
const comparisonResults = document.getElementById('comparison-results');
const comparisonBody = document.getElementById('comparison-body');

// Model hints
const modelHints = {
    'sentence-transformers': 'Default: all-MiniLM-L6-v2 (384 dims). Other options: all-mpnet-base-v2, paraphrase-multilingual-MiniLM-L12-v2',
    'openai': 'Default: text-embedding-3-small (1536 dims). Other option: text-embedding-3-large (3072 dims)',
    'google': 'Default: models/text-embedding-004 (768 dims)'
};

// Event Listeners
tabs.forEach(tab => tab.addEventListener('click', handleTabSwitch));
fileInput.addEventListener('change', handleFileSelect);
fileUploadArea.addEventListener('dragover', handleDragOver);
fileUploadArea.addEventListener('dragleave', handleDragLeave);
fileUploadArea.addEventListener('drop', handleDrop);
providerSelect.addEventListener('change', handleProviderChange);
generateBtn.addEventListener('click', handleGenerate);
downloadBtn.addEventListener('click', handleDownload);
clusterBtn.addEventListener('click', handleCluster);
resetBtn.addEventListener('click', handleReset);

// Comparison Listeners
fileInputB.addEventListener('change', handleFileSelectB);
generateBtnB.addEventListener('click', handleGenerateB);
thresholdInput.addEventListener('input', (e) => thresholdValue.textContent = e.target.value);
compareBtn.addEventListener('click', handleCompare);

// Initialize
handleProviderChange();

// Functions
function showAlert(message, type = 'info', duration = 5000) {
    alertDiv.textContent = message;
    alertDiv.className = `alert alert-${type} active`;

    // Only auto-hide if duration > 0
    if (duration > 0) {
        setTimeout(() => {
            alertDiv.classList.remove('active');
        }, duration);
    }
}

function handleDragOver(e) {
    e.preventDefault();
    fileUploadArea.classList.add('dragover');
}

function handleDragLeave(e) {
    e.preventDefault();
    fileUploadArea.classList.remove('dragover');
}

function handleDrop(e) {
    e.preventDefault();
    fileUploadArea.classList.remove('dragover');
    const files = e.dataTransfer.files;
    if (files.length > 0) {
        fileInput.files = files;
        handleFileSelect();
    }
}

async function handleFileSelect() {
    const file = fileInput.files[0];
    if (!file) return;

    if (!file.name.endsWith('.csv')) {
        showAlert('Please select a CSV file', 'error');
        return;
    }

    const formData = new FormData();
    formData.append('file', file);

    try {
        showAlert('Uploading and parsing CSV...', 'info');
        const response = await fetch('/api/upload', {
            method: 'POST',
            body: formData
        });

        const responseText = await response.text();
        console.log('Raw server response:', responseText);

        let data;
        try {
            data = JSON.parse(responseText);
        } catch (e) {
            console.error('JSON Parse Error:', e);
            throw new Error(`Server returned invalid JSON: ${responseText}`);
        }

        if (!response.ok) {
            throw new Error(data.error || 'Upload failed');
        }
        state.sessionId = data.session_id;
        state.columns = data.columns;

        // Update UI
        fileName.textContent = file.name;
        rowCount.textContent = data.row_count;
        fileInfo.classList.remove('hidden');
        configSection.classList.remove('hidden');

        // Populate column checkboxes
        populateColumns(data.columns);
        showAlert('CSV uploaded successfully!', 'success');

    } catch (error) {
        showAlert(error.message, 'error');
        console.error('Upload error:', error);
    }
}

function populateColumns(columns) {
    textColumnsDiv.innerHTML = '';
    metadataColumnsDiv.innerHTML = '';

    columns.forEach(col => {
        // Text columns
        const textDiv = document.createElement('div');
        textDiv.className = 'column-item';
        textDiv.innerHTML = `
            <input type="checkbox" id="text-${col}" value="${col}">
            <label for="text-${col}">${col}</label>
        `;
        textDiv.addEventListener('click', (e) => {
            if (e.target.tagName !== 'INPUT') {
                const checkbox = textDiv.querySelector('input');
                checkbox.checked = !checkbox.checked;
            }
        });
        textColumnsDiv.appendChild(textDiv);

        // Metadata columns
        const metaDiv = document.createElement('div');
        metaDiv.className = 'column-item';
        metaDiv.innerHTML = `
            <input type="checkbox" id="meta-${col}" value="${col}">
            <label for="meta-${col}">${col}</label>
        `;
        metaDiv.addEventListener('click', (e) => {
            if (e.target.tagName !== 'INPUT') {
                const checkbox = metaDiv.querySelector('input');
                checkbox.checked = !checkbox.checked;
            }
        });
        metadataColumnsDiv.appendChild(metaDiv);
    });
}

function handleProviderChange() {
    const provider = providerSelect.value;
    state.provider = provider;

    // Show/hide API key field
    if (provider === 'openai' || provider === 'google') {
        apiKeyGroup.classList.remove('hidden');
        modelGroup.classList.remove('hidden');
    } else {
        apiKeyGroup.classList.add('hidden');
        modelGroup.classList.remove('hidden');
    }

    // Update model hint
    modelHint.textContent = modelHints[provider];
}

async function handleGenerate() {
    // Collect selected columns
    const textCheckboxes = textColumnsDiv.querySelectorAll('input[type="checkbox"]:checked');
    const metaCheckboxes = metadataColumnsDiv.querySelectorAll('input[type="checkbox"]:checked');

    state.selectedTextColumns = Array.from(textCheckboxes).map(cb => cb.value);
    state.selectedMetadataColumns = Array.from(metaCheckboxes).map(cb => cb.value);

    if (state.selectedTextColumns.length === 0) {
        showAlert('Please select at least one column to embed', 'error');
        return;
    }

    // Get API key if needed
    if (state.provider !== 'sentence-transformers') {
        state.apiKey = apiKeyInput.value.trim();
        if (!state.apiKey) {
            showAlert('Please enter your API key', 'error');
            return;
        }
    }

    // Get model if specified
    state.model = modelInput.value.trim() || null;

    // Show progress
    progressSection.classList.add('active');
    generateBtn.disabled = true;
    generateBtn.innerHTML = '<span class="spinner"></span><span>Starting...</span>';

    try {
        // Start generation job
        const response = await fetch('/api/generate', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                session_id: state.sessionId,
                text_columns: state.selectedTextColumns,
                metadata_columns: state.selectedMetadataColumns,
                provider: state.provider,
                api_key: state.apiKey,
                model: state.model,
                combine_columns: combineCheckbox.checked
            })
        });

        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.error || 'Generation failed');
        }

        const data = await response.json();
        const jobId = data.job_id;

        // Poll for status
        generateBtn.innerHTML = '<span class="spinner"></span><span>Processing...</span>';

        const pollInterval = setInterval(async () => {
            try {
                const statusResponse = await fetch(`/api/status/${jobId}`);
                if (!statusResponse.ok) return;

                const statusData = await statusResponse.json();

                if (statusData.status === 'failed') {
                    clearInterval(pollInterval);
                    throw new Error(statusData.error || 'Job failed');
                }

                if (statusData.status === 'completed') {
                    clearInterval(pollInterval);

                    // Update UI
                    progressFill.style.width = '100%';
                    progressText.textContent = 'Complete!';

                    setTimeout(() => {
                        progressSection.classList.remove('active');
                        resultsSection.classList.remove('hidden');
                        embeddingCount.textContent = statusData.total;
                        embeddingDim.textContent = "Ready";

                        showAlert('Embeddings generated successfully!', 'success');
                        resetGenerationState();

                        // Update Comparison State
                        state.jobIdA = jobId;
                        updateSourceAStatus(true);

                        // Populate preview
                        populatePreview(jobId);
                    }, 500);
                }

                // Update progress bar
                if (statusData.total > 0) {
                    const percent = Math.round((statusData.processed / statusData.total) * 100);
                    progressFill.style.width = `${percent}%`;
                    progressText.textContent = `Processing: ${statusData.processed} / ${statusData.total} rows (${percent}%)`;
                }

            } catch (error) {
                clearInterval(pollInterval);
                showAlert(error.message, 'error');
                resetGenerationState();
            }

        }, 1000);

    } catch (error) {
        showAlert(error.message, 'error');
        console.error('Generation error:', error);
        resetGenerationState();
    }
}

function resetGenerationState() {
    generateBtn.disabled = false;
    generateBtn.innerHTML = '<span>Generate Embeddings</span>';
}

// Placeholder for preview population
async function populatePreview(jobId) {
    try {
        // We can reuse the download endpoint to get a few lines or just trust the user
        // For now, let's just clear the table or show a message
        // Ideally we'd have a /api/preview endpoint for embeddings
        previewBody.innerHTML = '<tr><td colspan="4">Preview available in downloaded file</td></tr>';
    } catch (e) {
        console.error(e);
    }
}

async function handleDownload() {
    const format = outputFormatSelect.value;
    const jobId = state.sessionId;

    if (!jobId) {
        showAlert('No active session', 'error');
        return;
    }

    try {
        downloadBtn.disabled = true;
        downloadBtn.innerHTML = '<span class="spinner"></span><span>Starting Download...</span>';

        const downloadUrl = `/api/download/${jobId}/${format}`;
        const a = document.createElement('a');
        a.href = downloadUrl;
        a.download = `embeddings_${format}.${format === 'jsonl' ? 'jsonl' : 'json'}`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);

        showAlert('Download started! Check your downloads folder.', 'success');

    } catch (error) {
        showAlert(error.message, 'error');
        console.error('Download error:', error);
    } finally {
        setTimeout(() => {
            downloadBtn.disabled = false;
            downloadBtn.innerHTML = '<span>📥 Download Embeddings</span>';
        }, 1000);
    }
}

async function handleCluster() {
    const jobId = state.sessionId;
    const nClusters = nClustersInput.value;

    if (!jobId) {
        showAlert('No active session', 'error');
        return;
    }

    try {
        clusterBtn.disabled = true;
        clusterBtn.innerHTML = '<span class="spinner"></span><span>Clustering...</span>';

        const response = await fetch('/api/cluster', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                session_id: jobId,
                n_clusters: nClusters
            })
        });

        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.error || 'Clustering failed');
        }

        const data = await response.json();

        // Show results
        clusterResults.classList.remove('hidden');
        clusterBody.innerHTML = '';

        data.summary.forEach(item => {
            const row = document.createElement('tr');
            row.innerHTML = `
                <td>${item.cluster}</td>
                <td>${item.count}</td>
            `;
            clusterBody.appendChild(row);
        });

        showAlert('Clustering complete! Download to see Cluster IDs.', 'success');

    } catch (error) {
        showAlert(error.message, 'error');
        console.error('Clustering error:', error);
    } finally {
        clusterBtn.disabled = false;
        clusterBtn.innerHTML = '<span>🧩 Cluster Data</span>';
    }
}

function handleReset() {
    state = {
        sessionId: null,
        columns: [],
        selectedTextColumns: [],
        selectedMetadataColumns: [],
        provider: 'sentence-transformers',
        apiKey: null,
        model: null,
        jobIdA: null,
        jobIdB: null,
        tempJobIdB: null,
        columnsB: []
    };

    fileInput.value = '';
    fileInfo.classList.add('hidden');
    configSection.classList.add('hidden');
    resultsSection.classList.add('hidden');
    progressSection.classList.remove('active');
    apiKeyInput.value = '';
    modelInput.value = '';
    providerSelect.value = 'sentence-transformers';
    handleProviderChange();

    // Reset Comparison UI
    updateSourceAStatus(false);
    fileInputB.value = '';
    sourceBUpload.classList.remove('hidden');
    sourceBConfig.classList.add('hidden');
    sourceBStatus.classList.add('hidden');
    comparisonResults.classList.add('hidden');
}

// --- Comparison Functions ---

function handleTabSwitch(e) {
    const tabId = e.target.dataset.tab;

    // Update buttons
    tabs.forEach(t => t.classList.remove('active'));
    e.target.classList.add('active');

    // Update content
    tabContents.forEach(c => {
        if (c.id === `tab-${tabId}`) {
            c.classList.remove('hidden');
            c.classList.add('active');
        } else {
            c.classList.add('hidden');
            c.classList.remove('active');
        }
    });
}

function updateSourceAStatus(ready) {
    if (ready) {
        sourceAStatus.className = 'status-box success';
        sourceAStatus.innerHTML = '<strong>✓ Ready</strong><br>Session ID: ' + state.jobIdA.substring(0, 8) + '...';
    } else {
        sourceAStatus.className = 'status-box pending';
        sourceAStatus.textContent = 'No active session. Go to Generator tab to load File A.';
    }
    checkCompareReady();
}

async function handleFileSelectB() {
    const file = fileInputB.files[0];
    if (!file) return;

    const formData = new FormData();
    formData.append('file', file);

    try {
        showAlert('Uploading File B...', 'info');
        const response = await fetch('/api/upload', { method: 'POST', body: formData });
        const data = await response.json();

        if (!response.ok) throw new Error(data.error || 'Upload failed');

        // Store temp session ID (not yet embedded)
        state.tempJobIdB = data.session_id;
        state.columnsB = data.columns;

        // Show config
        sourceBUpload.classList.add('hidden');
        sourceBConfig.classList.remove('hidden');

        // Populate dropdown
        textColumnBSelect.innerHTML = '';
        data.columns.forEach(col => {
            const option = document.createElement('option');
            option.value = col;
            option.textContent = col;
            textColumnBSelect.appendChild(option);
        });

    } catch (error) {
        showAlert(error.message, 'error');
    }
}

async function handleGenerateB() {
    const col = textColumnBSelect.value;
    const jobId = state.tempJobIdB;

    if (!jobId || !col) return;

    try {
        generateBtnB.disabled = true;
        generateBtnB.textContent = 'Generating...';

        // Reuse generate API
        const response = await fetch('/api/generate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                session_id: jobId,
                text_columns: [col],
                metadata_columns: [], // No metadata for B for simplicity
                provider: state.provider, // Use same provider as A
                api_key: state.apiKey,
                model: state.model,
                combine_columns: false
            })
        });

        if (!response.ok) throw new Error('Generation failed');

        // Poll
        const pollInterval = setInterval(async () => {
            try {
                const statusResponse = await fetch(`/api/status/${jobId}`);
                if (!statusResponse.ok) return;
                const statusData = await statusResponse.json();

                if (statusData.status === 'failed') {
                    clearInterval(pollInterval);
                    throw new Error(statusData.error);
                }
                if (statusData.status === 'completed') {
                    clearInterval(pollInterval);

                    // Success
                    state.jobIdB = jobId;
                    sourceBConfig.classList.add('hidden');
                    sourceBStatus.classList.remove('hidden');
                    sourceBStatus.className = 'status-box success';
                    sourceBStatus.innerHTML = '<strong>✓ Ready</strong><br>File B Embedded';

                    checkCompareReady();
                }

                if (statusData.total > 0) {
                    generateBtnB.textContent = `Processing... ${statusData.processed}/${statusData.total}`;
                }
            } catch (e) {
                clearInterval(pollInterval);
                showAlert(e.message, 'error');
                generateBtnB.disabled = false;
                generateBtnB.textContent = 'Generate Embeddings (File B)';
            }
        }, 1000);

    } catch (error) {
        showAlert(error.message, 'error');
        generateBtnB.disabled = false;
        generateBtnB.textContent = 'Generate Embeddings (File B)';
    }
}

function checkCompareReady() {
    if (state.jobIdA && state.jobIdB) {
        compareBtn.disabled = false;
    } else {
        compareBtn.disabled = true;
    }
}

async function handleCompare() {
    try {
        compareBtn.disabled = true;
        compareBtn.innerHTML = '<span class="spinner"></span> Comparing...';

        const response = await fetch('/api/compare', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                job_id_1: state.jobIdA,
                job_id_2: state.jobIdB,
                threshold: thresholdInput.value
            })
        });

        const data = await response.json();
        if (!response.ok) throw new Error(data.error);

        // Render results
        comparisonResults.classList.remove('hidden');
        comparisonBody.innerHTML = '';

        if (data.matches.length === 0) {
            comparisonBody.innerHTML = '<tr><td colspan="3">No matches found above threshold.</td></tr>';
        } else {
            data.matches.forEach(match => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${match.score.toFixed(4)}</td>
                    <td>${match.source_row.text}</td>
                    <td>${match.target_row.text}</td>
                `;
                comparisonBody.appendChild(row);
            });
        }

    } catch (error) {
        showAlert(error.message, 'error');
    } finally {
        compareBtn.disabled = false;
        compareBtn.innerHTML = '<span>🔍 Compare Files</span>';
    }
}
