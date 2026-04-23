import { Type, type Static } from "@sinclair/typebox";

export const CreateOptOutBodySchema = Type.Object({
  phone_number: Type.String({ minLength: 4 }),
});

export type CreateOptOutBody = Static<typeof CreateOptOutBodySchema>;

export const OptOutResponseSchema = Type.Object({
  phone_number: Type.String(),
});

export type OptOutResponse = Static<typeof OptOutResponseSchema>;
