// --- Navigation ---
const navItems = document.querySelectorAll('.nav-links li');
const tabContents = document.querySelectorAll('.tab-content');

navItems.forEach(item => {
    item.addEventListener('click', () => {
        // Active State
        navItems.forEach(nav => nav.classList.remove('active'));
        item.classList.add('active');

        // Show Content
        const tabId = item.dataset.tab;
        tabContents.forEach(content => {
            if (content.id === `tab-${tabId}`) {
                content.classList.remove('hidden');
                content.classList.add('active');
            } else {
                content.classList.add('hidden');
                content.classList.remove('active');
            }
        });
    });
});

// --- Data Setup ---

// Table Upload
const tableDropArea = document.getElementById('table-drop-area');
const tableFileInput = document.getElementById('table-file-input');
const tableNameInput = document.getElementById('table-name-input');
const uploadTableBtn = document.getElementById('upload-table-btn');
const tablesList = document.getElementById('tables-ul');

// Drag & Drop
['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
    tableDropArea.addEventListener(eventName, preventDefaults, false);
    document.getElementById('dict-drop-area').addEventListener(eventName, preventDefaults, false);
});

function preventDefaults(e) {
    e.preventDefault();
    e.stopPropagation();
}

tableDropArea.addEventListener('drop', handleTableDrop, false);
tableFileInput.addEventListener('change', (e) => handleTableFiles(e.target.files));

function handleTableDrop(e) {
    const dt = e.dataTransfer;
    const files = dt.files;
    handleTableFiles(files);
}

function handleTableFiles(files) {
    if (files.length > 0) {
        tableFileInput.files = files; // Set input files
        const file = files[0];
        tableDropArea.querySelector('.file-msg').textContent = file.name;
        if (!tableNameInput.value) {
            tableNameInput.value = file.name.replace('.csv', '').replace(/\W+/g, '_').toLowerCase();
        }
    }
}

uploadTableBtn.addEventListener('click', async () => {
    const files = tableFileInput.files;
    if (files.length === 0) return alert('Please select at least one CSV file.');

    uploadTableBtn.disabled = true;
    const originalText = uploadTableBtn.textContent;

    let successCount = 0;
    let failCount = 0;

    for (let i = 0; i < files.length; i++) {
        const file = files[i];
        uploadTableBtn.textContent = `Uploading ${i + 1}/${files.length}: ${file.name}...`;

        const formData = new FormData();
        formData.append('file', file);
        // Use filename as table name, sanitized
        const tableName = file.name.replace('.csv', '').replace(/\W+/g, '_').toLowerCase();
        formData.append('table_name', tableName);

        try {
            const res = await fetch('/api/upload_table', { method: 'POST', body: formData });
            const data = await res.json();

            if (res.ok) {
                addTableToList(data.table_name);
                successCount++;
            } else {
                console.error(`Failed to upload ${file.name}: ${data.error}`);
                failCount++;
            }
        } catch (e) {
            console.error(`Error uploading ${file.name}: ${e.message}`);
            failCount++;
        }
    }

    uploadTableBtn.disabled = false;
    uploadTableBtn.textContent = originalText;

    // Reset inputs
    tableFileInput.value = '';
    tableDropArea.querySelector('.file-msg').textContent = 'Drag & drop CSV here or click to upload';
    tableNameInput.value = '';

    if (failCount === 0) {
        alert(`Successfully uploaded all ${successCount} tables!`);
    } else {
        alert(`Uploaded ${successCount} tables. Failed to upload ${failCount} tables. Check console for details.`);
    }
});

function addTableToList(name) {
    const emptyMsg = tablesList.querySelector('.empty');
    if (emptyMsg) emptyMsg.remove();

    const li = document.createElement('li');
    li.innerHTML = `<span>${name}</span> <span style="color:var(--success)">✓ Ready</span>`;
    tablesList.appendChild(li);
}

// Dictionary Upload
const dictDropArea = document.getElementById('dict-drop-area');
const dictFileInput = document.getElementById('dict-file-input');
const uploadDictBtn = document.getElementById('upload-dict-btn');
const dictProvider = document.getElementById('dict-provider');
const dictApiKeyGroup = document.getElementById('dict-api-key-group');
const dictStatus = document.getElementById('dict-status');

dictDropArea.addEventListener('drop', (e) => {
    const files = e.dataTransfer.files;
    if (files.length > 0) {
        dictFileInput.files = files;
        dictDropArea.querySelector('.file-msg').textContent = files[0].name;
    }
});

dictFileInput.addEventListener('change', (e) => {
    if (e.target.files.length > 0) {
        dictDropArea.querySelector('.file-msg').textContent = e.target.files[0].name;
    }
});

dictProvider.addEventListener('change', () => {
    if (dictProvider.value === 'openai' || dictProvider.value === 'google') {
        dictApiKeyGroup.classList.remove('hidden');
    } else {
        dictApiKeyGroup.classList.add('hidden');
    }
});

uploadDictBtn.addEventListener('click', async () => {
    const file = dictFileInput.files[0];
    if (!file) return alert('Please select a Data Dictionary CSV.');

    const formData = new FormData();
    formData.append('file', file);
    formData.append('provider', dictProvider.value);

    const apiKey = document.getElementById('dict-api-key').value;
    if (apiKey) formData.append('api_key', apiKey);

    uploadDictBtn.disabled = true;
    uploadDictBtn.textContent = 'Uploading...';
    dictStatus.textContent = 'Step 1/2: Uploading Dictionary...';
    dictStatus.style.color = 'var(--text-color)';

    try {
        // We might want to separate upload and index if it takes too long, but for now we keep it simple.
        // We will update the text to "Indexing" after a short delay if it's still going, 
        // but since it's one request, we can't easily know when upload finishes and indexing starts without SSE/WebSockets.
        // However, we can just say "Processing & Indexing..."

        dictStatus.textContent = 'Processing & Indexing... This may take a moment.';

        const res = await fetch('/api/upload_dictionary', { method: 'POST', body: formData });
        const data = await res.json();

        if (res.ok) {
            if (data.warning) {
                dictStatus.textContent = '⚠️ ' + data.warning;
                dictStatus.style.color = '#ff9800'; // Orange for warning
            } else {
                dictStatus.textContent = '✅ ' + data.message;
                dictStatus.style.color = 'var(--success)';
            }
        } else {
            dictStatus.textContent = '❌ ' + (data.error || data.warning || 'Unknown error');
            dictStatus.style.color = 'var(--error)';
        }
    } catch (e) {
        dictStatus.textContent = '❌ Error: ' + e.message;
        dictStatus.style.color = 'var(--error)';
    } finally {
        uploadDictBtn.disabled = false;
        uploadDictBtn.textContent = 'Upload & Index Dictionary';
    }
});

// --- Query Logic ---
const askBtn = document.getElementById('ask-btn');
const userQuestion = document.getElementById('user-question');
const queryApiKey = document.getElementById('query-api-key');
const queryModel = document.getElementById('query-model');
const resultsArea = document.getElementById('query-results');
const sqlOutput = document.getElementById('sql-output');
const resultTable = document.getElementById('result-table');
const resultError = document.getElementById('result-error');
const schemaContext = document.getElementById('schema-context');

askBtn.addEventListener('click', async () => {
    const question = userQuestion.value.trim();
    const apiKey = queryApiKey.value.trim();

    if (!question) return alert('Please enter a question.');
    if (!apiKey) return alert('Gemini API Key is required for querying.');

    askBtn.disabled = true;
    askBtn.innerHTML = '<span class="spinner"></span> Thinking...';
    resultsArea.classList.add('hidden');

    let selectedModel = queryModel.value;
    if (selectedModel === 'custom') {
        selectedModel = document.getElementById('custom-model-input').value.trim();
    }

    try {
        const res = await fetch('/api/query', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                question: question,
                api_key: apiKey,
                model: selectedModel
            })
        });

        const data = await res.json();

        if (!res.ok) throw new Error(data.error || 'Query failed');

        // Render Results
        resultsArea.classList.remove('hidden');
        sqlOutput.textContent = data.sql;

        // Render Table
        resultTable.innerHTML = '';
        resultError.classList.add('hidden');

        if (data.error) {
            resultError.textContent = data.error;
            resultError.classList.remove('hidden');
        } else if (data.columns && data.rows) {
            // Header
            const thead = document.createElement('thead');
            const trHead = document.createElement('tr');
            data.columns.forEach(col => {
                const th = document.createElement('th');
                th.textContent = col;
                trHead.appendChild(th);
            });
            thead.appendChild(trHead);
            resultTable.appendChild(thead);

            // Body
            const tbody = document.createElement('tbody');
            if (data.rows.length === 0) {
                const tr = document.createElement('tr');
                tr.innerHTML = `<td colspan="${data.columns.length}">No results found.</td>`;
                tbody.appendChild(tr);
            } else {
                data.rows.forEach(row => {
                    const tr = document.createElement('tr');
                    row.forEach(cell => {
                        const td = document.createElement('td');
                        td.textContent = cell;
                        tr.appendChild(td);
                    });
                    tbody.appendChild(tr);
                });
            }
            resultTable.appendChild(tbody);
        }

        // Render Context
        schemaContext.innerHTML = '';
        if (data.relevant_schema) {
            data.relevant_schema.forEach(item => {
                const div = document.createElement('div');
                div.innerHTML = `<strong>${item.table_name}.${item.column_name}</strong>: ${item.description}`;
                schemaContext.appendChild(div);
            });
        }

    } catch (e) {
        alert('Error: ' + e.message);
    } finally {
        askBtn.disabled = false;
        askBtn.textContent = 'Ask Gemini';
    }
});

document.getElementById('copy-sql-btn').addEventListener('click', () => {
    navigator.clipboard.writeText(sqlOutput.textContent);
    alert('SQL copied to clipboard!');
});

function checkCustomModel(select) {
    const customInput = document.getElementById('custom-model-input');
    if (select.value === 'custom') {
        customInput.classList.remove('hidden');
    } else {
        customInput.classList.add('hidden');
    }
}
