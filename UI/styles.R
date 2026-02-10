# ============================================================================
# CSS Styles for the app
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

        .stat-box {
          background: white;
          border-radius: 16px;
          padding: 25px;
          box-shadow: 0 4px 15px rgba(0,0,0,0.08);
          cursor: pointer;
          transition: all 0.3s ease;
          height: 100%%;
        }

        .stat-box:hover {
          transform: translateY(-5px);
          box-shadow: 0 8px 25px rgba(0,0,0,0.12);
        }

        .stat-box.active {
          border: 3px solid %s;
          box-shadow: 0 8px 30px rgba(102, 126, 234, 0.3);
        }

        .stat-title {
          font-size: 22px;
          font-weight: bold;
          color: %s;
          margin-bottom: 20px;
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

        .chart-container {
          background: white;
          border-radius: 16px;
          padding: 30px;
          box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }

        .chart-title {
          font-size: 28px;
          font-weight: bold;
          color: %s;
          margin-bottom: 20px;
        }

        .btn-view {
          padding: 10px 20px;
          border-radius: 8px;
          border: none;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.2s ease;
          margin-right: 8px;
        }

        .btn-view.active {
          background: %s;
          color: white;
          box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
        }

        .btn-view:not(.active) {
          background: #F3F4F6;
          color: %s;
        }

        .status-badge {
          padding: 10px 20px;
          background: %s;
          color: white;
          border-radius: 20px;
          font-size: 14px;
          font-weight: bold;
        }

        .feedback-grid {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 12px;
          margin-top: 15px;
        }

        .feedback-item {
          background: #F9FAFB;
          border-radius: 10px;
          padding: 15px;
          text-align: center;
        }

        .feedback-item.positive { background: #E8F5E9; }
        .feedback-item.neutral { background: #E3F2FD; }
        .feedback-item.negative { background: #FFEBEE; }
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
                          colors$primary,
                          colors$dark,
                          colors$dark,
                          colors$primary,
                          colors$text_gray,
                          colors$live
    )))
  )
}
