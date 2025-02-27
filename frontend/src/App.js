// frontend/src/App.js
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link, Navigate } from 'react-router-dom';
import QueryDisplay from './components/QueryDisplay';
import QueryGraph from './components/QueryGraph'; // Updated import
import './styles/global.css';
import './styles/App.css';

function App() {
  return (
    <Router>
      <div className="App">
        <nav className="navbar">
          <ul className="nav-list">
            <li className="nav-item">
              <Link to="/query" className="nav-link">Query Display</Link>
            </li>
            <li className="nav-item">
              <Link to="/graph" className="nav-link">Query Graph</Link>
            </li>
          </ul>
        </nav>
        <main>
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
