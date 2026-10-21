# KODIGO URBAN · Tienda estática + panel admin

## 1. Supabase (el "cerebro")
1. Crea un proyecto en supabase.com.
2. SQL Editor > New query > pega `schema.sql` > Run.
3. Authentication > Users > Add user: crea tu correo y contraseña (marca "Auto confirm").
4. Authentication > Sign In / Providers > Email: desactiva "Allow new users to sign up" (así nadie más puede crear cuentas).
5. Project Settings > API: copia "Project URL" y la clave "anon public".

## 2. Configurar
Sube TODO el contenido del ZIP, incluida la carpeta `img/` (fotos de los primeros productos).
Abre `config.js` y pega URL y anon key. Sube todo a GitHub (Pages / Netlify / Vercel).

## 3. Panel admin
Entra con `tusitio/#admin`, o toca 5 veces el logo, o el punto "·" del pie de página.
- Productos: crear, editar, ocultar, eliminar. 6 fotos por producto; botón opcional "Añadir más fotos" (de 6 en 6).
- Banner y marca: promoción del inicio, texto de la barra superior y logo.

Cada producto genera su propio enlace de WhatsApp, y el carrito arma el pedido con los productos exactos.
Sin llenar `config.js` la tienda corre en modo demo (datos locales en el navegador).
