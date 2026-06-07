const express = require('express');
const fs = require('fs');
const path = require('path');
const cors = require('cors');
const multer = require('multer');

const app = express();
const PORT = process.env.PORT || 3001;

const uploadsDir = path.join(__dirname, '..', 'uploads');
const dataDir = path.join(__dirname, '..', 'data');
const mapsFile = path.join(dataDir, 'maps.json');
const clientDistDir = path.join(__dirname, '..', 'client', 'dist');

function ensureStorage() {
  fs.mkdirSync(uploadsDir, { recursive: true });
  fs.mkdirSync(dataDir, { recursive: true });

  if (!fs.existsSync(mapsFile)) {
    fs.writeFileSync(mapsFile, '[]', 'utf8');
  }
}

function readMaps() {
  ensureStorage();
  return JSON.parse(fs.readFileSync(mapsFile, 'utf8'));
}

function saveMaps(maps) {
  ensureStorage();
  fs.writeFileSync(mapsFile, JSON.stringify(maps, null, 2), 'utf8');
}

const upload = multer({
  storage: multer.diskStorage({
    destination: uploadsDir,
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname || '');
      const uniqueName = `${Date.now()}-${Math.random().toString(36).slice(2, 10)}${ext}`;
      cb(null, uniqueName);
    },
  }),
  fileFilter: (_req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/webm'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
      return;
    }

    cb(new Error('Only JPEG, PNG, WEBP, MP4, and WEBM files are supported.'));
  },
  limits: {
    fileSize: 50 * 1024 * 1024,
  },
});

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(uploadsDir));

app.get('/api/health', (_req, res) => {
  res.json({ ok: true, message: 'KnoxRPG digital terrain API is up.' });
});

app.get('/api/maps', (_req, res) => {
  res.json(readMaps());
});

app.get('/api/maps/active', (_req, res) => {
  const maps = readMaps();
  const activeMap = maps.find((map) => map.active) || maps[0] || null;
  res.json(activeMap);
});

app.post('/api/maps', upload.single('file'), (req, res, next) => {
  try {
    if (!req.file) {
      res.status(400).json({ error: 'A map file is required.' });
      return;
    }

    const maps = readMaps();
    const name = (req.body.name || path.parse(req.file.originalname).name).trim();
    const description = (req.body.description || '').trim();
    const type = req.file.mimetype.startsWith('video/') ? 'video' : 'image';

    const entry = {
      id: `${Date.now()}-${Math.random().toString(36).slice(2, 10)}`,
      name,
      description,
      type,
      originalName: req.file.originalname,
      fileName: req.file.filename,
      path: `/uploads/${req.file.filename}`,
      active: maps.length === 0,
      uploadedAt: new Date().toISOString(),
    };

    maps.push(entry);
    saveMaps(maps);
    res.status(201).json(entry);
  } catch (error) {
    next(error);
  }
});

app.put('/api/maps/:id', express.json(), (req, res) => {
  const maps = readMaps();
  const map = maps.find((entry) => entry.id === req.params.id);

  if (!map) {
    res.status(404).json({ error: 'Map not found.' });
    return;
  }

  map.name = (req.body.name || map.name).trim();
  map.description = (req.body.description ?? map.description).trim();

  saveMaps(maps);
  res.json(map);
});

app.put('/api/maps/:id/active', (req, res) => {
  const maps = readMaps();
  const map = maps.find((entry) => entry.id === req.params.id);

  if (!map) {
    res.status(404).json({ error: 'Map not found.' });
    return;
  }

  maps.forEach((entry) => {
    entry.active = entry.id === req.params.id;
  });

  saveMaps(maps);
  res.json(map);
});

app.delete('/api/maps/:id', (req, res) => {
  const maps = readMaps();
  const index = maps.findIndex((entry) => entry.id === req.params.id);

  if (index === -1) {
    res.status(404).json({ error: 'Map not found.' });
    return;
  }

  const [removedMap] = maps.splice(index, 1);
  const filePath = path.join(uploadsDir, removedMap.fileName);

  if (fs.existsSync(filePath)) {
    fs.unlinkSync(filePath);
  }

  saveMaps(maps);
  res.json({ ok: true, removed: removedMap });
});

app.use((error, _req, res, _next) => {
  if (error instanceof multer.MulterError) {
    res.status(400).json({ error: error.message });
    return;
  }

  res.status(400).json({ error: error.message || 'Unexpected upload error.' });
});

if (fs.existsSync(clientDistDir)) {
  app.use(express.static(clientDistDir));
  app.get('*', (_req, res) => {
    res.sendFile(path.join(clientDistDir, 'index.html'));
  });
} else {
  app.get('*', (_req, res) => {
    res.status(404).json({ error: 'The client build is not ready yet. Run npm run build first.' });
  });
}

app.listen(PORT, () => {
  console.log(`KnoxRPG terrain server listening on http://localhost:${PORT}`);
});
