import React, { useState, useEffect } from 'react';
import { AlertCircle } from 'lucide-react';
import './QueryDisplay.css';

const QueryDisplay = () => {
  const [queries, setQueries] = useState([]);
  const [selectedQuery, setSelectedQuery] = useState('');
  const [queryResults, setQueryResults] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const formatDisplayText = (text) => {
    const fileName = text.split('/').pop().replace(/\.sql$/, '');
    return fileName
      .split('_')
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
      .join(' ');
  };

  const formatColumnHeader = (header) => {
    return header.replace(/_/g, ' ');
  };

  useEffect(() => {
    fetchQueries();
  }, []);

  const fetchQueries = async () => {
    try {
      const response = await fetch('http://localhost:8000/available_queries');
      const data = await response.json();
      setQueries(data.queries);
    } catch (err) {
      console.error('Error fetching queries:', err);
      setError(`Failed to fetch available queries: ${err.message}`);
    }
  };

  const executeQuery = async (queryPath) => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch('http://localhost:8000/execute_query', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ query_path: queryPath }),
      });
      if (!response.ok) {
        throw new Error('Failed to execute query');
      }
      const data = await response.json();
      setQueryResults(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleQueryChange = (event) => {
    const value = event.target.value;
    setSelectedQuery(value);
    if (value) {
      executeQuery(value);
    }
  };

  return (
    <div className="query-display">
      <div className="query-display-header">
        <h2>World Bank Project Query Results</h2>
        <select
          value={selectedQuery}
          onChange={handleQueryChange}
          className="query-select"
        >
          <option value="">Select a query to execute</option>
          {queries.map((query) => (
            <option key={query} value={query} className="query-option">
              {formatDisplayText(query)}
            </option>
          ))}
        </select>

        {error && (
          <div className="error-container">
            <div className="error-title">
              <AlertCircle className="error-icon" />
              <span>Error</span>
            </div>
            <p className="error-text">{error}</p>
          </div>
        )}

        {loading && (
          <div className="loading">
            <span>Loading...</span>
          </div>
        )}
      </div>

      <div className="query-display-content">
        {queryResults && !loading && (
          <div className="results-wrapper">
            <div className="table-container">
              <div className="table-x-scroll">
                <div className="table-y-scroll">
                  <table className="query-table">
                    <thead>
                      <tr>
                        {queryResults.columns.map((column) => (
                          <th key={column}>{formatColumnHeader(column)}</th>
                        ))}
                      </tr>
                    </thead>
                    <tbody>
                      {queryResults.rows.map((row, rowIndex) => (
                        <tr
                          key={rowIndex}
                          className={rowIndex % 2 === 0 ? 'table-row-even' : 'table-row-odd'}
                        >
                          {queryResults.columns.map((column) => (
                            <td key={column}>
                              {row[column]?.toString() || ''}
                            </td>
                          ))}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
            <div className="results-summary">
              Total rows: {queryResults.total_rows}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default QueryDisplay;
