import { useEffect, useMemo, useRef, useState } from 'react';

function formatFileType(type) {
  return type === 'video' ? 'Video' : 'Image';
}

export default function App() {
  const [maps, setMaps] = useState([]);
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [uploading, setUploading] = useState(false);
  const [savingEdit, setSavingEdit] = useState(false);
  const [error, setError] = useState('');
  const [zoomLevel, setZoomLevel] = useState(1);
  const [editingMap, setEditingMap] = useState(null);
  const [editName, setEditName] = useState('');
  const [editDescription, setEditDescription] = useState('');
  const channelRef = useRef(null);

  const activeMap = useMemo(() => maps.find((map) => map.active) || maps[0] || null, [maps]);

  async function loadMaps() {
    const response = await fetch('/api/maps');
    const nextMaps = await response.json();
    setMaps(nextMaps);
  }

  useEffect(() => {
    const storedZoom = Number(localStorage.getItem('knoxrpg-zoom')) || 1;
    setZoomLevel(storedZoom);

    if (typeof BroadcastChannel !== 'undefined') {
      const channel = new BroadcastChannel('knoxrpg-display');
      channelRef.current = channel;
    }

    loadMaps().catch(() => setError('Unable to load maps right now.'));

    return () => {
      channelRef.current?.close();
    };
  }, []);

  async function syncDisplayZoom(level) {
    try {
      await fetch('/api/display/zoom', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ level }),
      });
    } catch (error) {
      // Fallback to local browser messaging when the server is unavailable.
    }
  }

  async function syncDisplayVideo(action) {
    try {
      await fetch('/api/display/video', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action }),
      });
    } catch (error) {
      // Fallback to local browser messaging when the server is unavailable.
    }
  }

  function updateZoom(delta) {
    const nextZoom = Math.min(2.5, Math.max(0.8, zoomLevel + delta));
    setZoomLevel(nextZoom);
    localStorage.setItem('knoxrpg-zoom', String(nextZoom));
    channelRef.current?.postMessage({ type: 'zoom', level: nextZoom });
    syncDisplayZoom(nextZoom).catch(() => {});
  }

  function sendVideoCommand(action) {
    channelRef.current?.postMessage({ type: 'video', action });
    syncDisplayVideo(action).catch(() => {});
  }

  async function handleUpload(event) {
    event.preventDefault();
    const file = event.target.file.files?.[0];

    if (!file) {
      setError('Select a JPEG, PNG, MP4, or WEBM file before uploading.');
      return;
    }

    setUploading(true);
    setError('');

    const formData = new FormData();
    formData.append('file', file);
    formData.append('name', name.trim() || file.name.replace(/\.[^.]+$/, ''));
    formData.append('description', description.trim());

    const response = await fetch('/api/maps', {
      method: 'POST',
      body: formData,
    });

    const payload = await response.json();

    if (!response.ok) {
      setError(payload.error || 'The map could not be uploaded.');
      setUploading(false);
      return;
    }

    event.target.reset();
    setName('');
    setDescription('');
    await loadMaps();
    setUploading(false);
  }

  async function handleSetActive(mapId) {
    const response = await fetch(`/api/maps/${mapId}/active`, { method: 'PUT' });
    if (response.ok) {
      await loadMaps();
    }
  }

  async function handleDelete(mapId) {
    const response = await fetch(`/api/maps/${mapId}`, { method: 'DELETE' });
    if (response.ok) {
      await loadMaps();
    }
  }

  function handleEditStart(mapId) {
    const currentMap = maps.find((map) => map.id === mapId);
    if (!currentMap) {
      return;
    }

    setEditingMap(currentMap);
    setEditName(currentMap.name);
    setEditDescription(currentMap.description || '');
    setError('');
  }

  async function handleEditSave(event) {
    event.preventDefault();

    if (!editingMap) {
      return;
    }

    setSavingEdit(true);
    setError('');

    const response = await fetch(`/api/maps/${editingMap.id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: editName.trim(),
        description: editDescription.trim(),
      }),
    });

    if (!response.ok) {
      const payload = await response.json().catch(() => ({}));
      setError(payload.error || 'The map could not be updated.');
      setSavingEdit(false);
      return;
    }

    await loadMaps();
    setEditingMap(null);
    setEditName('');
    setEditDescription('');
    setSavingEdit(false);
  }

  return (
    <div className="app-shell">
      <header className="hero-card">
        <div>
          <p className="eyebrow">KnoxRPG Digital Terrain</p>
          <h1 className="hero-title">KnoxRPG Digital Terrain</h1>
        </div>
        <a className="display-button" href="/display.html" target="_blank" rel="noreferrer">
          Open full-screen display
        </a>
      </header>

      <main className="dashboard-grid">
        <section className="panel">
          <div className="panel-heading">
            <div>
              <h2>Display controls</h2>
              <p className="muted">Adjust the wall display and the video playback without leaving the admin screen.</p>
            </div>
            <span className="badge">Zoom {zoomLevel.toFixed(2)}×</span>
          </div>
          <div className="control-row">
            <button type="button" className="secondary-button" onClick={() => updateZoom(-0.05)}>Zoom out</button>
            <button type="button" className="secondary-button" onClick={() => updateZoom(0.05)}>Zoom in</button>
            <button type="button" className="secondary-button" onClick={() => {
              setZoomLevel(1);
              localStorage.setItem('knoxrpg-zoom', '1');
              channelRef.current?.postMessage({ type: 'zoom', level: 1 });
              syncDisplayZoom(1).catch(() => {});
            }}>Reset</button>
          </div>
          {activeMap?.type === 'video' ? (
            <div className="control-row">
              <button type="button" className="secondary-button" onClick={() => sendVideoCommand('play')}>Play</button>
              <button type="button" className="secondary-button" onClick={() => sendVideoCommand('pause')}>Pause</button>
              <button type="button" className="secondary-button" onClick={() => sendVideoCommand('toggle-loop')}>Loop on/off</button>
            </div>
          ) : null}
          <h2>Upload a map</h2>
          <p className="muted">Supported types: JPEG, PNG, MP4, WEBM.</p>
          <form className="upload-form" onSubmit={handleUpload}>
            <label>
              Map name
              <input value={name} onChange={(event) => setName(event.target.value)} name="name" type="text" placeholder="Castle courtyard" />
            </label>
            <label>
              Description
              <textarea value={description} onChange={(event) => setDescription(event.target.value)} name="description" rows="3" placeholder="Describe what players should see." />
            </label>
            <label>
              File
              <input name="file" type="file" accept="image/jpeg,image/png,image/webp,video/mp4,video/webm" />
            </label>
            <button type="submit" disabled={uploading}>{uploading ? 'Uploading…' : 'Upload map'}</button>
          </form>
          {error ? <p className="error-text">{error}</p> : null}
        </section>

        <section className="panel preview-panel">
          <h2>Current active map</h2>
          {activeMap ? (
            <>
              <div className="preview-frame">
                {activeMap.type === 'video' ? (
                  <video src={activeMap.path} autoPlay muted loop playsInline controls />
                ) : (
                  <img src={activeMap.path} alt={activeMap.name} />
                )}
              </div>
              <div className="preview-copy">
                <h3>{activeMap.name}</h3>
                <p>{activeMap.description || 'No description provided.'}</p>
                <p className="muted">{formatFileType(activeMap.type)} • {new Date(activeMap.uploadedAt).toLocaleString()}</p>
              </div>
            </>
          ) : (
            <p className="muted">No maps have been uploaded yet. Start by adding one above.</p>
          )}
        </section>
      </main>

      <section className="panel map-list-panel">
        <div className="panel-heading">
          <div>
            <h2>Map library</h2>
            <p className="muted">Choose which terrain should appear on the main display.</p>
          </div>
          <span className="badge">{maps.length} total</span>
        </div>
        <div className="map-grid">
          {maps.map((map) => (
            <article className={`map-card ${map.active ? 'active' : ''}`} key={map.id}>
              <div className="thumb-frame">
                {map.type === 'video' ? (
                  <video src={map.path} muted loop playsInline />
                ) : (
                  <img src={map.path} alt={map.name} />
                )}
              </div>
              <div className="card-copy">
                <h3>{map.name}</h3>
                <p>{map.description || 'No description provided.'}</p>
                <p className="muted">{formatFileType(map.type)} • {new Date(map.uploadedAt).toLocaleString()}</p>
              </div>
              <div className="card-actions">
                <button onClick={() => handleSetActive(map.id)} className="secondary-button">
                  {map.active ? 'Active now' : 'Set as active'}
                </button>
                <button onClick={() => handleEditStart(map.id)} className="secondary-button">Edit</button>
                <button onClick={() => handleDelete(map.id)} className="danger-button">Delete</button>
              </div>
            </article>
          ))}
        </div>
      </section>

      {editingMap ? (
        <div className="modal-backdrop" onClick={() => setEditingMap(null)}>
          <form className="panel modal-card" onClick={(event) => event.stopPropagation()} onSubmit={handleEditSave}>
            <div>
              <p className="eyebrow">Edit map</p>
              <h2>{editingMap.name}</h2>
              <p className="muted">Update the map name and description shown in the admin panel.</p>
            </div>
            <label>
              Map name
              <input value={editName} onChange={(event) => setEditName(event.target.value)} type="text" />
            </label>
            <label>
              Description
              <textarea value={editDescription} onChange={(event) => setEditDescription(event.target.value)} rows="4" />
            </label>
            {error ? <p className="error-text">{error}</p> : null}
            <div className="modal-actions">
              <button type="button" className="secondary-button" onClick={() => setEditingMap(null)}>Cancel</button>
              <button type="submit" disabled={savingEdit}>{savingEdit ? 'Saving…' : 'Save changes'}</button>
            </div>
          </form>
        </div>
      ) : null}
    </div>
  );
}
