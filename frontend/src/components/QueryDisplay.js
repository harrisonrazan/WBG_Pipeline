import React, { useState, useEffect } from 'react';
import { AlertCircle } from 'lucide-react';

const QueryDisplay = () => {
  const [queries, setQueries] = useState([]);
  const [selectedQuery, setSelectedQuery] = useState('');
  const [queryResults, setQueryResults] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const formatDisplayText = (text) => {
    // Remove folder path and .sql extension
    const fileName = text.split('/').pop().replace(/\.sql$/, '');
    // Replace underscores with spaces and capitalize each word
    return fileName.split('_')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
      .join(' ');
  };

  const formatColumnHeader = (header) => {
    // Replace underscores with spaces
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
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          query_path: queryPath
        }),
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
    <div className="h-screen flex flex-col bg-gray-900">
      {/* Fixed Header Section */}
      <div className="bg-gray-800 shadow-md p-4 flex-none border-b border-gray-700">
        <h2 className="text-2xl font-bold mb-4 text-gray-100">World Bank Project Query Results</h2>
        
        <select
          value={selectedQuery}
          onChange={handleQueryChange}
          className="w-full p-3 border rounded-lg bg-gray-700 text-gray-100 border-gray-600 focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        >
          <option value="">Select a query to execute</option>
          {queries.map((query) => (
            <option key={query} value={query} className="bg-gray-700">
              {formatDisplayText(query)}
            </option>
          ))}
        </select>

        {/* Error Display */}
        {error && (
          <div className="mt-4 p-4 bg-red-900/50 border border-red-700 rounded-lg">
            <div className="flex items-center gap-2 text-red-400">
              <AlertCircle className="h-4 w-4" />
              <span className="font-semibold">Error</span>
            </div>
            <p className="mt-1 text-red-300">{error}</p>
          </div>
        )}

        {/* Loading State */}
        {loading && (
          <div className="mt-4 text-center">
            <span className="text-gray-300">Loading...</span>
          </div>
        )}
      </div>

      {/* Scrollable Content Area */}
      <div className="flex-grow overflow-hidden p-4 bg-gray-900">
        {queryResults && !loading && (
          <div className="h-full flex flex-col">
            {/* Table Container */}
            <div className="border border-gray-700 rounded-lg bg-gray-800 overflow-hidden flex-grow">
              <div className="overflow-x-auto">
                <div className="overflow-y-auto max-h-[calc(100vh-250px)]">
                  <table className="min-w-full divide-y divide-gray-700">
                    <thead className="bg-gray-800">
                      <tr>
                        {queryResults.columns.map((column) => (
                          <th
                            key={column}
                            className="sticky top-0 px-6 py-3 text-center text-xs font-medium text-gray-300 uppercase tracking-wider bg-gray-800 whitespace-nowrap border-b border-gray-700"
                          >
                            {formatColumnHeader(column)}
                          </th>
                        ))}
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-700">
                      {queryResults.rows.map((row, rowIndex) => (
                        <tr 
                          key={rowIndex}
                          className={rowIndex % 2 === 0 ? 'bg-gray-800' : 'bg-gray-900'}
                        >
                          {queryResults.columns.map((column) => (
                            <td
                              key={column}
                              className="px-6 py-4 whitespace-nowrap text-sm text-gray-300 text-center"
                            >
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
            
            {/* Results Summary */}
            <div className="mt-4 text-sm text-gray-400">
              Total rows: {queryResults.total_rows}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default QueryDisplay;