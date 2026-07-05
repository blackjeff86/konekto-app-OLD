import { neonConfig } from '@neondatabase/serverless'
import ws from 'ws'

// Node.js (runtime da Vercel e do `next dev`/scripts locais) não tem um
// WebSocket global estável ainda — o driver serverless da Neon precisa
// que a gente informe qual implementação usar.
neonConfig.webSocketConstructor = ws
