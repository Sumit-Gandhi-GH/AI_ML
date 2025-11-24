'use client';

import { useState } from 'react';
import Header from '../components/Header';
import Sidebar from '../components/Sidebar';
import FileUpload from '../components/FileUpload';
import AutoDashboard from '../components/AutoDashboard';
import DataQualityReport from '../components/DataQualityReport';
import VisualizationPanel from '../components/VisualizationPanel';
import ChatInterface from '../components/ChatInterface';
import styles from './page.module.css';

export default function Home() {
  const [activeTab, setActiveTab] = useState('upload');

  const renderContent = () => {
    switch (activeTab) {
      case 'upload':
        return <FileUpload />;
      case 'auto':
        return <AutoDashboard />;
      case 'quality':
        return <DataQualityReport />;
      case 'visualize':
        return <VisualizationPanel />;
      case 'chat':
        return <ChatInterface />;
      default:
        return <FileUpload />;
    }
  };

  return (
    <div className={styles.app}>
      <Header />
      <div className={styles.layout}>
        <Sidebar activeTab={activeTab} onTabChange={setActiveTab} />
        <main className={styles.main}>
          {renderContent()}
        </main>
      </div>
    </div>
  );
}

