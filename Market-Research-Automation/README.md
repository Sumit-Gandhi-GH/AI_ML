# Market Research Automation at Scale

A modern, AI-powered web application for automating firmographic research at scale. Upload a CSV of companies and leverage multiple LLM providers to extract comprehensive market intelligence.

![Market Research Automation](https://img.shields.io/badge/Status-Ready-success)
![License](https://img.shields.io/badge/License-MIT-blue)

## Features

### 🚀 Core Capabilities
- **Bulk CSV Upload**: Process hundreds of companies simultaneously
- **Multi-LLM Support**: Choose from Gemini, ChatGPT, Claude Sonnet, or Grok
- **Customizable Prompts**: Define your own research parameters and system instructions
- **Real-time Progress**: Track research progress with live updates
- **Export Options**: Download results as CSV or JSON

### 📊 Firmographic Data Extraction
- Annual Revenue
- Employee Count
- Website URL
- Email Domain
- Industry & Sub-Industry
- Headquarters Location
- LinkedIn Company Page

### 🎨 Modern UI/UX
- Dark mode design with gradient effects
- Smooth animations and transitions
- Responsive layout for all devices
- Interactive data visualization
- Drag-and-drop file upload

## Getting Started

### Prerequisites
- A modern web browser (Chrome, Firefox, Safari, Edge)
- API key for your chosen LLM provider:
  - [Google AI Studio](https://makersuite.google.com/app/apikey) for Gemini
  - [OpenAI Platform](https://platform.openai.com/api-keys) for ChatGPT
  - [Anthropic Console](https://console.anthropic.com/) for Claude
  - [xAI](https://x.ai/) for Grok

### Installation

1. **Clone or Download** this repository
2. **Open** `index.html` in your web browser
3. That's it! No build process or dependencies required.

### Usage

#### Step 1: Upload Your Company List
1. Navigate to the **Upload** section
2. Click or drag-and-drop your CSV file
3. Ensure your CSV contains company names or domains in the first column

**Example CSV Format:**
```csv
Company Name,Domain
Acme Corporation,acme.com
TechStart Inc,techstart.io
Global Solutions,globalsolutions.com
```

#### Step 2: Configure Research Parameters
1. Navigate to the **Configure** section
2. Select your preferred AI model
3. Enter your API key (stored locally, never sent to our servers)
4. Customize the system instructions (optional)
5. Modify the research prompt to match your needs (optional)

**Default Prompt:**
The application includes a comprehensive default prompt designed for firmographic research. You can customize it to focus on specific data points or add additional fields.

#### Step 3: Start Research
1. Click **Start Research** to begin processing
2. Monitor progress in real-time
3. View results as they complete

#### Step 4: Export Results
1. Navigate to the **Results** section
2. Click **Export CSV** or **Export JSON**
3. Save the file to your preferred location

## Configuration

### API Keys
API keys are stored in your browser's localStorage and are never transmitted to external servers (except to the LLM provider you select). To clear your saved settings:

```javascript
localStorage.removeItem('marketResearchSettings');
```

### Custom Prompts
The research prompt supports the following placeholder:
- `{company_name}` - Replaced with each company identifier from your CSV

**Example Custom Prompt:**
```
Research {company_name} and provide:
1. Current CEO name
2. Year founded
3. Latest funding round
4. Main competitors
```

## Technical Details

### Architecture
- **Frontend**: Pure HTML5, CSS3, and Vanilla JavaScript
- **Styling**: Custom CSS design system with CSS variables
- **Data Processing**: Client-side CSV parsing
- **Storage**: Browser localStorage for settings persistence

### Browser Compatibility
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

### File Structure
```
Market-Research-Automation/
├── index.html          # Main application structure
├── index.css           # Design system and styles
├── app.js              # Application logic
└── README.md           # Documentation
```

## Customization

### Styling
The application uses CSS variables for easy customization. Edit `index.css` to modify:
- Color palette (`:root` variables)
- Spacing and layout
- Typography
- Animations

### Adding New LLM Providers
To add a new LLM provider:

1. Add the option in `index.html`:
```html
<label class="llm-option">
    <input type="radio" name="llm" value="new-provider">
    <div class="llm-card">
        <!-- Provider details -->
    </div>
</label>
```

2. Update the API integration in `app.js` (currently simulated)

## Roadmap

- [ ] Real LLM API integration
- [ ] Batch processing optimization
- [ ] Advanced filtering and search
- [ ] Data validation and enrichment
- [ ] Team collaboration features
- [ ] API rate limiting and retry logic
- [ ] Cost estimation and tracking

## Security & Privacy

- **API Keys**: Stored locally in browser, never sent to third parties
- **Data Processing**: All CSV parsing happens client-side
- **No Server**: Static application, no backend required
- **HTTPS Recommended**: Use HTTPS when deploying to production

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Contact: [your-email@example.com]

## Acknowledgments

- Built with modern web standards
- Inspired by the need for scalable market research automation
- Designed for researchers, analysts, and business development professionals

---

**Note**: This application currently includes simulated LLM responses for demonstration purposes. To use real AI models, you'll need to integrate the respective API endpoints in `app.js`.
