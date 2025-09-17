import React, { useState, useEffect } from 'react';
import axios from 'axios';

const Data = () => {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [newItem, setNewItem] = useState({ name: '', type: '', status: 'active' });
  const [showForm, setShowForm] = useState(false);
  const [submitLoading, setSubmitLoading] = useState(false);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      const response = await axios.get('/api/data');
      setData(response.data.data || []);
      setError(null);
    } catch (err) {
      setError('Failed to load data');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!newItem.name || !newItem.type) return;

    try {
      setSubmitLoading(true);
      await axios.post('/api/data', newItem);
      setNewItem({ name: '', type: '', status: 'active' });
      setShowForm(false);
      await fetchData(); // Refresh data
    } catch (err) {
      setError('Failed to create item');
    } finally {
      setSubmitLoading(false);
    }
  };

  const getStatusBadgeClass = (status) => {
    switch (status.toLowerCase()) {
      case 'active': return 'bg-success';
      case 'inactive': return 'bg-secondary';
      case 'pending': return 'bg-warning';
      case 'error': return 'bg-danger';
      default: return 'bg-primary';
    }
  };

  if (loading) {
    return (
      <div className="loading-spinner">
        <div className="spinner-border text-primary" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
      </div>
    );
  }

  return (
    <div>
      <div className="row mb-4">
        <div className="col-12">
          <div className="card">
            <div className="card-body d-flex justify-content-between align-items-center">
              <div>
                <h1 className="card-title mb-1">
                  <i className="fas fa-database text-info me-3"></i>
                  Data Management
                </h1>
                <p className="card-text text-muted mb-0">
                  Manage and view application data through the API
                </p>
              </div>
              <button
                className="btn btn-primary"
                onClick={() => setShowForm(!showForm)}
              >
                <i className="fas fa-plus me-2"></i>
                Add Item
              </button>
            </div>
          </div>
        </div>
      </div>

      {error && (
        <div className="error-message">
          <i className="fas fa-exclamation-triangle me-2"></i>
          {error}
        </div>
      )}

      {/* Add Item Form */}
      {showForm && (
        <div className="row mb-4">
          <div className="col-md-6">
            <div className="card">
              <div className="card-header">
                <h5 className="mb-0">
                  <i className="fas fa-plus-circle me-2"></i>
                  Add New Item
                </h5>
              </div>
              <div className="card-body">
                <form onSubmit={handleSubmit}>
                  <div className="mb-3">
                    <label className="form-label">Name *</label>
                    <input
                      type="text"
                      className="form-control"
                      value={newItem.name}
                      onChange={(e) => setNewItem({...newItem, name: e.target.value})}
                      required
                      placeholder="Enter item name"
                    />
                  </div>
                  <div className="mb-3">
                    <label className="form-label">Type *</label>
                    <input
                      type="text"
                      className="form-control"
                      value={newItem.type}
                      onChange={(e) => setNewItem({...newItem, type: e.target.value})}
                      required
                      placeholder="Enter item type"
                    />
                  </div>
                  <div className="mb-3">
                    <label className="form-label">Status</label>
                    <select
                      className="form-select"
                      value={newItem.status}
                      onChange={(e) => setNewItem({...newItem, status: e.target.value})}
                    >
                      <option value="active">Active</option>
                      <option value="inactive">Inactive</option>
                      <option value="pending">Pending</option>
                    </select>
                  </div>
                  <div className="d-flex gap-2">
                    <button
                      type="submit"
                      className="btn btn-primary"
                      disabled={submitLoading || !newItem.name || !newItem.type}
                    >
                      {submitLoading ? (
                        <><i className="fas fa-spinner fa-spin me-2"></i>Creating...</>
                      ) : (
                        <><i className="fas fa-save me-2"></i>Create Item</>
                      )}
                    </button>
                    <button
                      type="button"
                      className="btn btn-secondary"
                      onClick={() => {
                        setShowForm(false);
                        setNewItem({ name: '', type: '', status: 'active' });
                      }}
                    >
                      Cancel
                    </button>
                  </div>
                </form>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Data Table */}
      <div className="row">
        <div className="col-12">
          <div className="card">
            <div className="card-header d-flex justify-content-between align-items-center">
              <h5 className="mb-0">
                <i className="fas fa-list me-2"></i>
                Data Items ({data.length})
              </h5>
              <button
                className="btn btn-outline-primary btn-sm"
                onClick={fetchData}
                disabled={loading}
              >
                <i className={`fas fa-sync-alt me-2 ${loading ? 'fa-spin' : ''}`}></i>
                Refresh
              </button>
            </div>
            <div className="card-body">
              {data.length === 0 ? (
                <div className="text-center py-5 text-muted">
                  <i className="fas fa-inbox fa-3x mb-3"></i>
                  <h5>No Data Available</h5>
                  <p>Add some items to see them here.</p>
                </div>
              ) : (
                <div className="table-responsive">
                  <table className="table table-hover">
                    <thead>
                      <tr>
                        <th>ID</th>
                        <th>Name</th>
                        <th>Type</th>
                        <th>Status</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {data.map((item) => (
                        <tr key={item.id}>
                          <td>
                            <code>{item.id}</code>
                          </td>
                          <td>
                            <strong>{item.name}</strong>
                          </td>
                          <td>
                            <span className="text-muted">{item.type}</span>
                          </td>
                          <td>
                            <span className={`badge ${getStatusBadgeClass(item.status)}`}>
                              {item.status}
                            </span>
                          </td>
                          <td>
                            <button
                              className="btn btn-outline-info btn-sm me-2"
                              title="View Details"
                            >
                              <i className="fas fa-eye"></i>
                            </button>
                            <button
                              className="btn btn-outline-warning btn-sm me-2"
                              title="Edit"
                            >
                              <i className="fas fa-edit"></i>
                            </button>
                            <button
                              className="btn btn-outline-danger btn-sm"
                              title="Delete"
                            >
                              <i className="fas fa-trash"></i>
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Statistics */}
      {data.length > 0 && (
        <div className="row mt-4">
          <div className="col-md-3">
            <div className="card text-center">
              <div className="card-body">
                <h3 className="text-primary">{data.length}</h3>
                <p className="text-muted mb-0">Total Items</p>
              </div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="card text-center">
              <div className="card-body">
                <h3 className="text-success">{data.filter(item => item.status === 'active').length}</h3>
                <p className="text-muted mb-0">Active</p>
              </div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="card text-center">
              <div className="card-body">
                <h3 className="text-warning">{data.filter(item => item.status === 'pending').length}</h3>
                <p className="text-muted mb-0">Pending</p>
              </div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="card text-center">
              <div className="card-body">
                <h3 className="text-secondary">{data.filter(item => item.status === 'inactive').length}</h3>
                <p className="text-muted mb-0">Inactive</p>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Data;