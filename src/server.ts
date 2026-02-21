import { buildApp } from "./app.js";

const start = async () => {
  try {
    const app = await buildApp();
    await app.listen({
      port: app.config.PORT,
      host: app.config.HOST,
    });
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};

start();
