import { Router } from "express";
import authRoutes from "./auth.routes.js";

const router = Router();

router.get("/health", (_req, res) => {
  res.json({ status: "ok", service: "apharma-api" });
});

router.use("/auth", authRoutes);

export default router;
