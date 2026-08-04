import { app } from "./app.ts";

const port = process.env.PORT ? Number(process.env.PORT) : 3000;

app.listen(port, () => {
  console.log(`wheres-my-order listening on port ${port}`);
});
