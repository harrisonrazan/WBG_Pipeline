# Build stage
FROM node:18 as build

WORKDIR /app

# Copy package files
COPY package.json ./

# Install dependencies including Tailwind and other new packages
RUN npm install
RUN npm install -D tailwindcss postcss autoprefixer lucide-react

# Copy source code
COPY . .

# Initialize Tailwind
RUN npx tailwindcss init -p

# Build the app
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy built assets from build stage
COPY --from=build /app/build /usr/share/nginx/html

# Copy nginx config if you have custom configuration
# COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]