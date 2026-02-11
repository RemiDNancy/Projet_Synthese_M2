# ============================================================================
# CSS Styles for the app - Version avec styles sentiment améliorés
# ============================================================================
app_styles <- function() {
  tags$head(
    tags$style(HTML(sprintf("
        /* ============= STYLES GLOBAUX ============= */
        .content-wrapper, .right-side {
          background: linear-gradient(135deg, #EEF2FF 0%%, #F3E8FF 50%%, #DBEAFE 100%%);
        }

        .main-header .logo {
          background: linear-gradient(135deg, %s 0%%, %s 100%%) !important;
          height: 50px;
          line-height: 50px;
          padding: 0 15px;
          display: flex;
          align-items: center;
        }

        .main-header .navbar {
          background: linear-gradient(135deg, %s 0%%, %s 100%%) !important;
        }

        .sidebar-menu > li.active > a {
          background-color: %s !important;
        }

        /* ============= STYLES HOME ============= */
        .page-title {
          font-size: 32px;
          font-weight: bold;
          color: %s;
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
          background: %s;
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
          color: %s;
          margin-bottom: 5px;
        }

        .project-category {
          font-size: 13px;
          color: %s;
          margin-bottom: 5px;
        }

        .project-status {
          font-size: 13px;
          font-weight: bold;
          margin-bottom: 10px;
        }

        .progress-bar-container {
          width: 100%%;
          height: 8px;
          background: %s;
          border-radius: 4px;
          overflow: hidden;
          margin-bottom: 5px;
        }

        .progress-bar-fill {
          height: 100%%;
          border-radius: 4px;
          transition: width 0.3s ease;
        }

        .progress-percent {
          font-size: 14px;
          font-weight: bold;
          color: %s;
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
          background: linear-gradient(135deg, %s 0%%, %s 100%%);
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
          height: 100%%;
          margin-bottom: 20px;
        }

        .stat-box.ai-insights {
          background: linear-gradient(135deg, #667EEA 0%%, #764BA2 100%%);
          color: white;
        }

        .stat-title {
          font-size: 22px;
          font-weight: bold;
          color: %s;
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
          background: linear-gradient(135deg, #D1FAE5 0%%, #A7F3D0 100%%);
        }

        .quick-stat.blue {
          background: linear-gradient(135deg, #DBEAFE 0%%, #BFDBFE 100%%);
        }

        .quick-stat.orange {
          background: linear-gradient(135deg, #FEF3C7 0%%, #FDE68A 100%%);
        }

        .quick-stat.purple {
          background: linear-gradient(135deg, #F3E8FF 0%%, #E9D5FF 100%%);
        }

        .chart-container {
          background: white;
          border-radius: 16px;
          padding: 30px;
          box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }

        .status-badge {
          padding: 10px 20px;
          background: %s;
          color: white;
          border-radius: 20px;
          font-size: 14px;
          font-weight: bold;
        }

        /* ============= SENTIMENT STYLES (NOUVEAU) ============= */
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
          width: 100%%;
          height: 8px;
          background: #E5E7EB;
          border-radius: 4px;
          overflow: hidden;
        }

        .comm-bar-fill {
          height: 100%%;
          border-radius: 4px;
          transition: width 0.4s ease;
        }
      ",
                            colors$primary, colors$secondary,
                            colors$primary, colors$secondary,
                            colors$primary,
                            colors$dark,
                            colors$bg_light,
                            colors$dark,
                            colors$text_gray,
                            colors$border,
                            colors$dark,
                            colors$primary, colors$secondary,
                            colors$dark,
                            colors$live
    )))
  )
}