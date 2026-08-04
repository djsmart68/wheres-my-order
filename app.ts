import express from "express";
import { getOrderStatus, isValidOrderNumber } from "./status.ts";

export const app = express();

app.get("/health", (_req, res) => {
  res.status(200).json({ status: "ok" });
});

app.get("/api/status/:orderNumber", (req, res) => {
  const { orderNumber } = req.params;

  if (!isValidOrderNumber(orderNumber)) {
    res.status(400).json({
      error: "Order number must be 6 to 10 digits.",
    });
    return;
  }

  res.status(200).json(getOrderStatus(orderNumber));
});

app.use(express.static("public"));
