import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import QueryDisplay from './components/QueryDisplay';
import QueryGraph from './components/QueryGraph';
// import './styles/global.css';
import './styles/Navbar.css';

// NavLink component to handle active state
const NavLink = ({ to, children }) => {
  const location = useLocation();
  const isActive = location.pathname === to || 
                  (location.pathname === '/' && to === '/query');
  
  return (
    <Link 
      to={to} 
      className={`nav-link ${isActive ? 'active' : ''}`}
    >
      {children}
    </Link>
  );
};

function App() {
  return (
    <Router>
      <div className="app-container">
        <nav className="navbar">
          <div className="navbar-container">
            <Link to="/" className="brand-logo">World Bank Data</Link>
            <ul className="nav-list">
              <li className="nav-item">
                <NavLink to="/query">Query Display</NavLink>
              </li>
              <li className="nav-item">
                <NavLink to="/graph">Query Graph</NavLink>
              </li>
            </ul>
          </div>
        </nav>
        <main className="main-content">
          <Routes>
            <Route path="/query" element={<QueryDisplay />} />
            <Route path="/graph" element={<QueryGraph />} />
            {/* Default route */}
            <Route path="/" element={<QueryDisplay />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;