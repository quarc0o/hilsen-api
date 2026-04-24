import { Type, type Static } from "@sinclair/typebox";

export const CreateDemoSendBodySchema = Type.Object({
  phone_number: Type.String({ minLength: 4 }),
});

export type CreateDemoSendBody = Static<typeof CreateDemoSendBodySchema>;

export const DemoSendResponseSchema = Type.Object({
  ok: Type.Literal(true),
  card_send_id: Type.String({ format: "uuid" }),
});

export type DemoSendResponse = Static<typeof DemoSendResponseSchema>;

export const DemoSendErrorSchema = Type.Object({
  error: Type.String(),
});

export type DemoSendError = Static<typeof DemoSendErrorSchema>;
