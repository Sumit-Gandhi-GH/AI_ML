'use client';

import React, { useState, useEffect } from 'react';
import { useDashboardStore } from '../store/useStore';
import { analyzeBusinessQuery, generateAutomatedInsights } from '../utils/analytics';
import styles from './ChatInterface.module.css';

interface Message {
    id: string;
    text: string;
    sender: 'user' | 'bot';
    timestamp: number;
}

export default function ChatInterface() {
    const { cleanData, columns } = useDashboardStore();
    const [messages, setMessages] = useState<Message[]>([]);
    const [input, setInput] = useState('');
    const [isTyping, setIsTyping] = useState(false);

    useEffect(() => {
        // Initialize with welcome message and auto-insights
        if (cleanData.length > 0 && messages.length === 0) {
            const insights = generateAutomatedInsights(cleanData, columns);

            const welcomeMsg: Message = {
                id: '1',
                text: `👋 **Welcome to your Data Assistant!**\n\nI've analyzed your dataset and found some interesting insights. Here's what I discovered:\n\n${insights.slice(0, 3).map(i => `**${i.title}**\n${i.description}`).join('\n\n')}\n\n💬 Ask me anything about your data! Try:\n• "What are the top performers?"\n• "Show me sales analysis"\n• "What roles are relevant for sales?"\n• "Give me more insights"`,
                sender: 'bot',
                timestamp: Date.now(),
            };

            setMessages([welcomeMsg]);
        } else if (cleanData.length === 0 && messages.length === 0) {
            setMessages([{
                id: '1',
                text: '👋 Hello! Please upload your data first, and I\'ll help you analyze it with advanced insights and business intelligence.',
                sender: 'bot',
                timestamp: Date.now(),
            }]);
        }
    }, [cleanData, columns]);

    const generateResponse = (question: string): string => {
        const lowerQuestion = question.toLowerCase();

        // Use advanced business analytics
        if (cleanData.length > 0) {
            // Check for insights request
            if (lowerQuestion.includes('insight') || lowerQuestion.includes('find') || lowerQuestion.includes('discover')) {
                const insights = generateAutomatedInsights(cleanData, columns);
                return `**🔍 Automated Insights:**\n\n` +
                    insights.map((i, idx) => `**${idx + 1}. ${i.title}** (${(i.confidence * 100).toFixed(0)}% confidence)\n${i.description}`).join('\n\n');
            }

            // Use business query analyzer
            return analyzeBusinessQuery(question, cleanData, columns);
        }

        // Fallback for basic questions
        if (lowerQuestion.includes('column') || lowerQuestion.includes('field')) {
            return columns.length > 0
                ? `📋 **Your Columns:**\n\n${columns.map((c, i) => `${i + 1}. ${c}`).join('\n')}`
                : 'No data loaded yet. Please upload a CSV file first.';
        }

        if (lowerQuestion.includes('row') || lowerQuestion.includes('record')) {
            return cleanData.length > 0
                ? `📊 Your dataset contains **${cleanData.length.toLocaleString()} rows**`
                : 'No data loaded yet.';
        }

        if (lowerQuestion.includes('help')) {
            return `**🤖 I can help you with:**\n\n` +
                `📊 **Business Analytics:**\n` +
                `• Sales analysis and trends\n` +
                `• Top/bottom performers\n` +
                `• Role and distribution analysis\n` +
                `• Automated insights\n\n` +
                `📈 **Data Exploration:**\n` +
                `• Column information\n` +
                `• Statistical summaries\n` +
                `• Correlation suggestions\n` +
                `• Outlier detection\n\n` +
                `💡 **Try asking:**\n` +
                `"What insights can you find?"\n` +
                `"Analyze sales performance"\n` +
                `"What are the top 5 performers?"\n` +
                `"Show me role distribution"`;
        }

        return `I can help you analyze your data! Try asking:\n\n` +
            `• "What insights can you find?"\n` +
            `• "Analyze sales trends"\n` +
            `• "What are the top performers?"\n` +
            `• "Show me role distribution"\n` +
            `• "Help" for more options`;
    };

    const handleSend = () => {
        if (!input.trim()) return;

        const userMessage: Message = {
            id: Date.now().toString(),
            text: input,
            sender: 'user',
            timestamp: Date.now(),
        };

        setMessages(prev => [...prev, userMessage]);
        setInput('');
        setIsTyping(true);

        // Simulate typing delay for more natural feel
        setTimeout(() => {
            const botMessage: Message = {
                id: (Date.now() + 1).toString(),
                text: generateResponse(input),
                sender: 'bot',
                timestamp: Date.now(),
            };
            setMessages(prev => [...prev, botMessage]);
            setIsTyping(false);
        }, 800);
    };

    return (
        <div className={styles.container}>
            <div className={styles.header}>
                <h2>🤖 Data Assistant</h2>
                <div className={styles.status}>
                    <div className={styles.statusDot}></div>
                    {isTyping ? 'Analyzing...' : 'Online'}
                </div>
            </div>

            <div className={styles.messagesContainer}>
                {messages.map((message) => (
                    <div
                        key={message.id}
                        className={`${styles.message} ${message.sender === 'user' ? styles.userMessage : styles.botMessage}`}
                    >
                        <div className={styles.messageContent}>
                            {message.text.split('\n').map((line, i) => {
                                // Handle markdown-style bold
                                const parts = line.split(/(\*\*.*?\*\*)/g);
                                return (
                                    <div key={i}>
                                        {parts.map((part, j) => {
                                            if (part.startsWith('**') && part.endsWith('**')) {
                                                return <strong key={j}>{part.slice(2, -2)}</strong>;
                                            }
                                            return <span key={j}>{part}</span>;
                                        })}
                                    </div>
                                );
                            })}
                        </div>
                        <div className={styles.messageTime}>
                            {new Date(message.timestamp).toLocaleTimeString()}
                        </div>
                    </div>
                ))}

                {isTyping && (
                    <div className={`${styles.message} ${styles.botMessage}`}>
                        <div className={styles.typingIndicator}>
                            <span></span>
                            <span></span>
                            <span></span>
                        </div>
                    </div>
                )}
            </div>

            <div className={styles.inputContainer}>
                <input
                    type="text"
                    placeholder="Ask me about your data..."
                    value={input}
                    onChange={(e) => setInput(e.target.value)}
                    onKeyPress={(e) => e.key === 'Enter' && handleSend()}
                />
                <button onClick={handleSend} disabled={!input.trim()}>
                    <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                        <path d="M10.894 2.553a1 1 0 00-1.788 0l-7 14a1 1 0 001.169 1.409l5-1.429A1 1 0 009 15.571V11a1 1 0 112 0v4.571a1 1 0 00.725.962l5 1.428a1 1 0 001.17-1.408l-7-14z" />
                    </svg>
                </button>
            </div>
        </div>
    );
}
