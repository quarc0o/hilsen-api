// usecases.ts
import {
  ConversationRepository,
  ChatMessageRepository,
  ScheduleChatMessageRepository,
} from "./repositories.ts";
import { DeliveryStatus, ScheduledCard } from "./types.ts";

export class FindConversationUsecase {
  constructor(private conversationRepository: ConversationRepository) {}

  async execute(participants: string[]): Promise<string | null> {
    return await this.conversationRepository.getConversationIdByParticipants(
      participants
    );
  }
}

export class CreateConversationUsecase {
  constructor(private conversationRepository: ConversationRepository) {}

  async execute(participants: string[]): Promise<string | Error> {
    return await this.conversationRepository.createConversationWithParticipants(
      participants
    );
  }
}

export class UpdateDeliveryStatusUsecase {
  constructor(private chatMessageRepository: ChatMessageRepository) {}

  async execute(
    deliveryStatus: DeliveryStatus,
    chatMessageId: string,
    conversationId: string
  ) {
    await this.chatMessageRepository.updateGiftDeliveryStatus(
      deliveryStatus,
      chatMessageId,
      conversationId
    );
  }
}

export class ScheduleChatMessageUsecase {
  constructor(
    private scheduleChatMessageRepository: ScheduleChatMessageRepository
  ) {}

  async execute(scheduledMessage: ScheduledCard) {
    await this.scheduleChatMessageRepository.scheduleChatMessageForSending(
      scheduledMessage
    );
  }
}
