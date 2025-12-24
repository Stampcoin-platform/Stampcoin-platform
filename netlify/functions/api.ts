import type { Handler, HandlerEvent, HandlerContext } from "@netlify/functions";
import serverlessExpress from "@vendia/serverless-express";
import { app } from "../../server/_core/serverless";

const handler = serverlessExpress({ app });

export { handler };
