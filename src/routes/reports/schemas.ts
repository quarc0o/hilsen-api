import { Type, type Static } from "@sinclair/typebox";

export const CreateReportBodySchema = Type.Object({
  send_id: Type.String({ format: "uuid" }),
  reason: Type.String({ minLength: 1, maxLength: 2000 }),
});

export type CreateReportBody = Static<typeof CreateReportBodySchema>;

export const ReportResponseSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
});

export type ReportResponse = Static<typeof ReportResponseSchema>;
