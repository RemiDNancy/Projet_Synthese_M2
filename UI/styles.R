# ============================================================================
# CSS Styles for the app - Complete version with all tabs
# ============================================================================
app_styles <- function() {
  css <- paste0("
        /* ============= STYLES GLOBAUX ============= */
        .content-wrapper, .right-side {
          background: linear-gradient(135deg, #EEF2FF 0%, #F3E8FF 50%, #DBEAFE 100%);
        }

        .main-header .logo {
          background: linear-gradient(135deg, ", colors$primary, " 0%, ", colors$secondary, " 100%) !important;
          height: 50px;
          line-height: 50px;
          padding: 0 15px;
          display: flex;
          align-items: center;
        }

        .main-header .navbar {
          background: linear-gradient(135deg, ", colors$primary, " 0%, ", colors$secondary, " 100%) !important;
        }

        .sidebar-menu > li.active > a {
          background-color: ", colors$primary, " !important;
        }

        /* ============= STYLES HOME ============= */
        .page-title {
          font-size: 32px;
          font-weight: bold;
          color: ", colors$dark, ";
          margin-bottom: 20px;
        }

        .filter-section {
          background: white;
          padding: 20px;
          border-radius: 12px;
          margin-bottom: 20px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        .project-card {
          background: white;
          border-radius: 12px;
          padding: 15px;
          margin-bottom: 20px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          transition: transform 0.2s, box-shadow 0.2s;
          cursor: pointer;
        }

        .project-card:hover {
          transform: translateY(-5px);
          box-shadow: 0 4px 16px rgba(0,0,0,0.15);
        }

        .project-image {
          width: 80px;
          height: 80px;
          background: ", colors$bg_light, ";
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 40px;
          margin-bottom: 10px;
        }

        .project-title {
          font-size: 16px;
          font-weight: bold;
          color: ", colors$dark, ";
          margin-bottom: 5px;
        }

        .project-category {
          font-size: 13px;
          color: ", colors$text_gray, ";
          margin-bottom: 5px;
        }

        .project-status {
          font-size: 13px;
          font-weight: bold;
          margin-bottom: 10px;
        }

        .progress-bar-container {
          width: 100%;
          height: 8px;
          background: ", colors$border, ";
          border-radius: 4px;
          overflow: hidden;
          margin-bottom: 5px;
        }

        .progress-bar-fill {
          height: 100%;
          border-radius: 4px;
          transition: width 0.3s ease;
        }

        .progress-percent {
          font-size: 14px;
          font-weight: bold;
          color: ", colors$dark, ";
        }

        /* ============= STYLES PROJECT DASHBOARD ============= */
        .project-header {
          background: white;
          border-radius: 16px;
          padding: 25px;
          margin-bottom: 20px;
          box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }

        .project-header:hover {
          box-shadow: 0 15px 40px rgba(0,0,0,0.15);
        }

        /* ============= TAB NAVIGATION ============= */
        .tab-navigation {
          background: white;
          border-radius: 16px;
          padding: 16px;
          margin-bottom: 24px;
          box-shadow: 0 4px 15px rgba(0,0,0,0.08);
          display: flex;
          gap: 8px;
          overflow-x: auto;
        }

        .nav-tab {
          padding: 12px 24px;
          border-radius: 12px;
          border: none;
          font-weight: 600;
          font-size: 15px;
          cursor: pointer;
          transition: all 0.3s ease;
          background: #F3F4F6;
          color: #6B7280;
          white-space: nowrap;
        }

        .nav-tab:hover {
          background: #E5E7EB;
          transform: translateY(-2px);
        }

        .nav-tab.active {
          background: linear-gradient(135deg, ", colors$primary, " 0%, ", colors$secondary, " 100%);
          color: white;
          box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
          transform: scale(1.05);
        }

        .nav-tab i {
          margin-right: 8px;
        }

        /* ============= TAB CONTENT ============= */
        .dash-tab-content {
          display: none;
        }

        .dash-tab-content.active {
          display: block;
          animation: fadeIn 0.3s ease-in;
        }

        @keyframes fadeIn {
          from {
            opacity: 0;
            transform: translateY(10px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }

        .stat-box {
          background: white;
          border-radius: 16px;
          padding: 25px;
          box-shadow: 0 4px 15px rgba(0,0,0,0.08);
          height: 100%;
          margin-bottom: 20px;
        }

        .stat-box.ai-insights {
          background: linear-gradient(135deg, #667EEA 0%, #764BA2 100%);
          color: white;
        }

        .stat-title {
          font-size: 22px;
          font-weight: bold;
          color: ", colors$dark, ";
          margin-bottom: 20px;
          display: flex;
          align-items: center;
        }

        .stat-box.ai-insights .stat-title {
          color: white;
        }

        .mini-stat {
          background: #FAFAFA;
          border-radius: 10px;
          padding: 12px;
          margin-bottom: 10px;
          transition: all 0.2s ease;
        }

        .mini-stat:hover {
          background: #EEF2FF;
          transform: scale(1.05);
        }

        /* Quick Stats Grid */
        .quick-stats-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 12px;
        }

        .quick-stat {
          padding: 20px;
          border-radius: 12px;
          text-align: center;
          transition: all 0.2s ease;
        }

        .quick-stat:hover {
          transform: translateY(-3px);
          box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }

        .quick-stat.green {
          background: linear-gradient(135deg, #D1FAE5 0%, #A7F3D0 100%);
        }

        .quick-stat.blue {
          background: linear-gradient(135deg, #DBEAFE 0%, #BFDBFE 100%);
        }

        .quick-stat.orange {
          background: linear-gradient(135deg, #FEF3C7 0%, #FDE68A 100%);
        }

        .quick-stat.purple {
          background: linear-gradient(135deg, #F3E8FF 0%, #E9D5FF 100%);
        }

        .chart-container {
          background: white;
          border-radius: 16px;
          padding: 30px;
          box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }

        .status-badge {
          padding: 10px 20px;
          background: ", colors$live, ";
          color: white;
          border-radius: 20px;
          font-size: 14px;
          font-weight: bold;
        }

        /* ============= SENTIMENT STYLES ============= */
        .sentiment-feedback-grid {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 12px;
          margin-top: 15px;
        }

        .sentiment-feedback-item {
          background: #F9FAFB;
          border-radius: 10px;
          padding: 15px;
          text-align: center;
        }

        /* ============= COMMUNICATION BARS (Sentiment) ============= */
        .comm-bar-item {
          margin-bottom: 12px;
        }

        .comm-bar-bg {
          width: 100%;
          height: 8px;
          background: #E5E7EB;
          border-radius: 4px;
          overflow: hidden;
        }

        .comm-bar-fill {
          height: 100%;
          border-radius: 4px;
          transition: width 0.4s ease;
        }

        /* ============= REWARDS STYLES ============= */
        .rewards-stat-card {
          transition: all 0.3s ease;
        }

        .rewards-stat-card:hover {
          transform: translateY(-5px);
          box-shadow: 0 8px 25px rgba(0,0,0,0.12) !important;
        }

        .btn-filter-rewards {
          transition: all 0.2s ease;
        }

        .btn-filter-rewards:hover {
          transform: scale(1.05);
          box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        }

        .btn-filter-rewards.active {
          box-shadow: 0 4px 12px rgba(5,206,120,0.4);
        }

        /* ============= CREATOR TAB STYLES ============= */
        .creator-profile-card {
          background: white;
          border-radius: 16px;
          padding: 25px;
          margin-bottom: 20px;
          box-shadow: 0 4px 15px rgba(0,0,0,0.08);
          transition: all 0.3s ease;
        }

        .creator-profile-card:hover {
          box-shadow: 0 6px 20px rgba(0,0,0,0.12);
        }

        .creator-avatar {
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .creator-quick-stats {
          display: flex;
          align-items: center;
          justify-content: space-around;
        }

        .creator-stat-mini {
          text-align: center;
          padding: 10px;
          transition: all 0.2s ease;
        }

        .creator-stat-mini:hover {
          transform: scale(1.1);
        }

        .badge-present {
          animation: pulse 2s infinite;
        }

        .badge-rewards {
          transition: all 0.3s ease;
        }

        .badge-rewards:hover {
          transform: scale(1.1);
        }

        @keyframes pulse {
          0%, 100% {
            transform: scale(1);
          }
          50% {
            transform: scale(1.05);
          }
        }

        #creator_projects_timeline {
          padding: 20px 0;
        }

        .timeline-item {
          border-left: 3px solid #667EEA;
          padding-left: 20px;
          margin-bottom: 20px;
          position: relative;
          transition: all 0.3s ease;
        }

        .timeline-item::before {
          content: '';
          position: absolute;
          left: -8px;
          top: 5px;
          width: 13px;
          height: 13px;
          border-radius: 50%;
          background: #667EEA;
          border: 3px solid white;
          transition: all 0.3s ease;
        }

        .timeline-item:hover {
          border-left-color: #F39C12;
        }

        .timeline-item:hover::before {
          background: #F39C12;
          transform: scale(1.3);
        }

        /* ============= AI INSIGHTS TAB STYLES ============= */

        /* AI Model Cards (Top Section) */
        .ai-model-card {
          background: white;
          border-radius: 16px;
          padding: 25px;
          margin-bottom: 20px;
          cursor: pointer;
          transition: all 0.3s ease;
          box-shadow: 0 4px 15px rgba(0,0,0,0.08);
          position: relative;
          border: 3px solid transparent;
        }

        .ai-model-card:hover {
          transform: translateY(-5px);
          box-shadow: 0 8px 25px rgba(0,0,0,0.15);
        }

        .ai-model-card.active {
          border-color: #F59E0B;
          box-shadow: 0 8px 30px rgba(0,0,0,0.2);
        }

        /* Oracle Card - Indigo Theme */
        .oracle-card {
          background: linear-gradient(135deg, #5B6AD4 0%, #4A58C2 100%);
          color: white;
        }

        /* Sage Card - Teal Theme */
        .sage-card {
          background: linear-gradient(135deg, #2A8F74 0%, #1E7A61 100%);
          color: white;
        }

        /* Card Header */
        .ai-model-header {
          display: flex;
          align-items: center;
          gap: 15px;
          margin-bottom: 20px;
          position: relative;
        }

        .ai-model-icon {
          width: 60px;
          height: 60px;
          border-radius: 12px;
          display: flex;
          align-items: center;
          justify-content: center;
          background: rgba(255,255,255,0.2);
          color: white;
        }

        .ai-model-info {
          flex: 1;
        }

        .ai-model-name {
          font-size: 24px;
          font-weight: bold;
          margin-bottom: 3px;
        }

        .ai-model-subtitle {
          font-size: 13px;
          opacity: 0.8;
        }

        .ai-favorite-badge {
          position: absolute;
          top: -5px;
          right: 0;
          font-size: 24px;
        }

        /* Prediction Section */
        .ai-prediction-section {
          margin-bottom: 20px;
        }

        .ai-prediction-value {
          font-size: 48px;
          font-weight: bold;
          margin-bottom: 10px;
          color: white;
        }

        .ai-prediction-bar {
          width: 100%;
          height: 12px;
          background: rgba(255,255,255,0.2);
          border-radius: 6px;
          overflow: hidden;
        }

        .ai-prediction-fill {
          height: 100%;
          border-radius: 6px;
          transition: width 0.8s ease;
          background: white;
        }

        /* Metrics Grid */
        .ai-metrics-grid {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 15px;
          margin-bottom: 15px;
        }

        .ai-metric-item {
          text-align: center;
          padding: 12px;
          background: rgba(255,255,255,0.1);
          border-radius: 10px;
          transition: all 0.2s ease;
        }

        .ai-metric-item:hover {
          background: rgba(255,255,255,0.2);
          transform: scale(1.05);
        }

        .ai-metric-label {
          font-size: 11px;
          opacity: 0.8;
          margin-bottom: 5px;
        }

        .ai-metric-value {
          font-size: 20px;
          font-weight: bold;
        }

        .ai-card-footer {
          font-size: 12px;
          opacity: 0.7;
          text-align: center;
          margin-top: 10px;
        }

        /* Analysis Panel (Bottom Section) */
        .ai-analysis-panel {
          display: none;
          animation: fadeInUp 0.4s ease;
        }

        .ai-analysis-panel.active {
          display: block;
        }

        @keyframes fadeInUp {
          from {
            opacity: 0;
            transform: translateY(20px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }

        /* Both analysis panels share the same neutral background */
        .oracle-panel, .sage-panel {
          background: #F8F7F4;
          border-radius: 16px;
          padding: 30px;
          color: #2C3E50;
          border: 1px solid #E5E7EB;
        }

        /* Title colors stay model-specific */
        .oracle-panel .ai-analysis-title { color: #5B6AD4; }
        .sage-panel   .ai-analysis-title { color: #2A8F74; }

        /* Analysis Header */
        .ai-analysis-header {
          display: flex;
          align-items: center;
          gap: 15px;
          margin-bottom: 30px;
          padding-bottom: 20px;
          border-bottom: 2px solid #E5E7EB;
        }

        .ai-analysis-icon {
          width: 50px;
          height: 50px;
          border-radius: 12px;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 24px;
          background: #ECEEF8;
        }

        .oracle-panel .ai-analysis-icon { background: rgba(91,106,212,0.12); }
        .sage-panel   .ai-analysis-icon { background: rgba(42,143,116,0.12); }

        .ai-analysis-title {
          font-size: 28px;
          font-weight: bold;
        }

        .ai-analysis-subtitle {
          font-size: 14px;
          color: #6B7280;
          font-weight: normal;
        }

        /* Detail Boxes */
        .ai-detail-box {
          background: #FFFFFF;
          border-radius: 12px;
          padding: 20px;
          margin-bottom: 20px;
          border: 1px solid #E5E7EB;
        }

        .ai-detail-header {
          font-size: 16px;
          font-weight: bold;
          margin-bottom: 15px;
          display: flex;
          align-items: center;
          color: #2C3E50;
        }

        .ai-detail-list {
          display: flex;
          flex-direction: column;
          gap: 12px;
        }

        .ai-detail-item {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 10px 0;
          border-bottom: 1px solid #E5E7EB;
        }

        .ai-detail-item:last-child {
          border-bottom: none;
        }

        .ai-detail-label {
          font-size: 14px;
          color: #6B7280;
          display: flex;
          align-items: center;
        }

        .ai-detail-value {
          font-size: 18px;
          font-weight: bold;
          color: #2C3E50;
        }

        /* Success Factors */
        .ai-factor-list {
          display: flex;
          flex-direction: column;
          gap: 15px;
        }

        .ai-factor-item {
          padding: 12px 0;
        }

        .ai-factor-name {
          font-size: 14px;
          margin-bottom: 5px;
          color: #6B7280;
        }

        .ai-factor-score {
          display: flex;
          justify-content: space-between;
          align-items: center;
          font-size: 18px;
          font-weight: bold;
          margin-bottom: 8px;
          color: #2C3E50;
        }

        .ai-badge {
          padding: 3px 10px;
          border-radius: 12px;
          font-size: 11px;
          font-weight: 600;
        }

        .ai-badge.hot {
          background: #EF4444;
          color: white;
        }

        .ai-badge.medium {
          background: #F59E0B;
          color: white;
        }

        .ai-factor-bar {
          width: 100%;
          height: 6px;
          background: #E5E7EB;
          border-radius: 3px;
        }

        /* Comparison Box */
        .ai-comparison-box {
          background: #FFFFFF;
          border-radius: 16px;
          padding: 25px;
          margin-top: 20px;
          border: 1px solid #E5E7EB;
        }

        .ai-comparison-header {
          font-size: 18px;
          font-weight: bold;
          margin-bottom: 20px;
          display: flex;
          align-items: center;
          color: #2C3E50;
        }

        .ai-compare-item {
          background: #F9FAFB;
          border-radius: 12px;
          padding: 20px;
          border: 1px solid #E5E7EB;
        }

        .ai-compare-model {
          display: flex;
          align-items: center;
          gap: 12px;
          margin-bottom: 12px;
        }

        .ai-compare-icon {
          width: 40px;
          height: 40px;
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
          background: #ECEEF8;
        }

        .oracle-compare .ai-compare-icon { background: rgba(91,106,212,0.12); }
        .sage-compare   .ai-compare-icon { background: rgba(42,143,116,0.12); }

        .ai-compare-info {
          font-size: 14px;
          color: #2C3E50;
        }

        .ai-compare-subtitle {
          font-size: 11px;
          color: #95A5A6;
        }

        .ai-compare-prediction {
          font-size: 42px;
          font-weight: bold;
          margin: 12px 0;
          color: #2C3E50;
        }

        .ai-compare-bar {
          width: 100%;
          height: 8px;
          background: #E5E7EB;
          border-radius: 4px;
          margin-bottom: 8px;
        }

        .ai-compare-confidence {
          font-size: 12px;
          color: #95A5A6;
        }

        /* Gap Indicator */
        .ai-gap-indicator {
          text-align: center;
          padding: 20px 10px;
        }

        .ai-gap-label {
          font-size: 12px;
          color: #6B7280;
          margin-bottom: 5px;
        }

        .ai-gap-value {
          font-size: 32px;
          font-weight: bold;
          margin-bottom: 10px;
          color: #2C3E50;
        }

        .ai-gap-note {
          font-size: 13px;
          color: #6B7280;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 5px;
        }

        /* Switch Button */
        .ai-switch-btn {
          transition: all 0.3s ease;
        }

        .ai-switch-btn:hover {
          transform: scale(1.05);
          box-shadow: 0 6px 20px rgba(0,0,0,0.2) !important;
        }
        /* ============= GLOBAL ANALYTICS PAGE STYLES ============= */
        
        /* Analytics Header */
        .analytics-header {
          background: linear-gradient(135deg, #667EEA 0%, #764BA2 100%);
          border-radius: 16px;
          padding: 30px 40px;
          margin-bottom: 30px;
          display: flex;
          align-items: center;
          gap: 20px;
          box-shadow: 0 10px 30px rgba(102, 126, 234, 0.3);
        }
        
        .analytics-header-icon {
          color: white;
          opacity: 0.9;
        }
        
        .analytics-header-text {
          flex: 1;
        }
        
        /* Analytics Stat Cards (Top 4 cards) */
        .analytics-stat-card {
          background: linear-gradient(135deg, #EEF2FF 0%, #F3E8FF 100%);
          border-radius: 16px;
          padding: 25px;
          margin-bottom: 20px;
          box-shadow: 0 4px 15px rgba(0,0,0,0.08);
          display: flex;
          align-items: center;
          gap: 20px;
          transition: all 0.3s ease;
        }
        
        .analytics-stat-card:hover {
          transform: translateY(-5px);
          box-shadow: 0 8px 25px rgba(0,0,0,0.15);
        }
        
        .analytics-stat-icon {
          width: 70px;
          height: 70px;
          border-radius: 14px;
          display: flex;
          align-items: center;
          justify-content: center;
          color: white;
        }
        
        .analytics-stat-icon.purple {
          background: linear-gradient(135deg, #667EEA 0%, #764BA2 100%);
        }
        
        .analytics-stat-icon.green {
          background: linear-gradient(135deg, #10B981 0%, #059669 100%);
        }
        
        .analytics-stat-icon.blue {
          background: linear-gradient(135deg, #3B82F6 0%, #2563EB 100%);
        }
        
        .analytics-stat-icon.orange {
          background: linear-gradient(135deg, #F59E0B 0%, #D97706 100%);
        }
        
        .analytics-stat-content {
          flex: 1;
        }
        
        .analytics-stat-label {
          font-size: 13px;
          color: #95A5A6;
          margin-bottom: 5px;
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }
        
        .analytics-stat-value {
          font-size: 36px;
          font-weight: bold;
          color: #2C3E50;
          line-height: 1;
        }
        
        /* Analytics Chart Boxes */
        .analytics-chart-box {
          background: linear-gradient(135deg, #EEF2FF 0%, #F3E8FF 100%);
          border-radius: 16px;
          padding: 25px;
          margin-bottom: 20px;
          box-shadow: 0 4px 15px rgba(0,0,0,0.08);
          transition: all 0.3s ease;
        }
        
        .analytics-chart-box:hover {
          box-shadow: 0 6px 20px rgba(0,0,0,0.12);
        }
        
        .analytics-chart-header {
          display: flex;
          align-items: center;
          margin-bottom: 20px;
          padding-bottom: 15px;
          border-bottom: 2px solid #F3F4F6;
        }
        
        /* Responsive adjustments */
        @media (max-width: 768px) {
          .analytics-stat-card {
            flex-direction: column;
            text-align: center;
          }
          
          .analytics-stat-value {
            font-size: 28px;
          }
          
          .analytics-header {
            flex-direction: column;
            text-align: center;
          }
        }

        /* ============= ZOOM BUTTONS ============= */
        .zoom-btn-row {
          display: flex;
          justify-content: flex-end;
          gap: 6px;
          margin-bottom: 8px;
        }

        .zoom-btn {
          background: linear-gradient(135deg, #667EEA 0%, #764BA2 100%);
          color: white;
          border: none;
          border-radius: 8px;
          width: 32px;
          height: 32px;
          cursor: pointer;
          font-size: 13px;
          display: inline-flex;
          align-items: center;
          justify-content: center;
          transition: all 0.2s ease;
          box-shadow: 0 2px 6px rgba(102,126,234,0.3);
          padding: 0;
        }

        .zoom-btn:hover {
          transform: scale(1.15);
          box-shadow: 0 4px 12px rgba(102,126,234,0.5);
        }

        /* ============= ABOUT US PAGE STYLES ============= */

        /* Header banner */
        .about-header {
          background: linear-gradient(135deg, #667EEA 0%, #764BA2 100%);
          border-radius: 20px;
          padding: 40px 50px;
          margin-bottom: 32px;
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 20px;
          text-align: center;
          box-shadow: 0 12px 35px rgba(102, 126, 234, 0.35);
        }

        .about-logo-wrap {
          background: rgba(255,255,255,0.15);
          border-radius: 16px;
          padding: 16px;
          width: 100%;
        }

        .about-uni-logo {
          width: 100%;
          height: auto;
          display: block;
          object-fit: cover;
          border-radius: 8px;
        }

        .about-header-text {
          width: 100%;
        }

        .about-app-name {
          font-size: 42px;
          font-weight: 800;
          color: white;
          letter-spacing: -0.5px;
          margin-bottom: 6px;
        }

        .about-project-title {
          font-size: 20px;
          font-weight: 600;
          color: rgba(255,255,255,0.95);
          margin-bottom: 10px;
        }

        .about-project-sub {
          font-size: 15px;
          color: rgba(255,255,255,0.75);
        }

        /* Team section wrapper */
        .about-team-section {
          background: linear-gradient(135deg, #EEF2FF 0%, #F3E8FF 100%);
          border-radius: 20px;
          padding: 40px;
          box-shadow: 0 4px 15px rgba(0,0,0,0.07);
        }

        .about-team-heading {
          font-size: 26px;
          font-weight: bold;
          color: #2C3E50;
          display: flex;
          align-items: center;
          margin-bottom: 36px;
        }

        /* Flex grid — 5 cards wrap naturally into 3+2 */
        .about-team-grid {
          display: flex;
          flex-wrap: wrap;
          justify-content: center;
          gap: 28px;
        }

        /* Individual person card */
        .about-person-card {
          background: linear-gradient(135deg, #667EEA 0%, #764BA2 100%);
          border-radius: 20px;
          padding: 36px 28px;
          width: 200px;
          text-align: center;
          box-shadow: 0 6px 20px rgba(102, 126, 234, 0.3);
          transition: all 0.3s ease;
        }

        .about-person-card:hover {
          transform: translateY(-8px);
          box-shadow: 0 14px 35px rgba(102, 126, 234, 0.45);
        }

        /* Avatar circle */
        .about-person-avatar {
          width: 90px;
          height: 90px;
          border-radius: 50%;
          background: rgba(255,255,255,0.2);
          display: flex;
          align-items: center;
          justify-content: center;
          margin: 0 auto 20px auto;
          color: white;
          border: 3px solid rgba(255,255,255,0.4);
        }

        .about-person-name {
          font-size: 17px;
          font-weight: 700;
          color: white;
          margin-bottom: 4px;
        }

        .about-person-surname {
          font-size: 15px;
          font-weight: 400;
          color: rgba(255,255,255,0.8);
        }
  ")

  tags$head(tags$style(HTML(css)))
}