import type { ChatService } from '@/types';
import type {
  Conversation,
  CreateConversationRequest,
  UpdateConversationRequest,
  Message,
  SendMessageRequest,
  ExpertProfile,
  ExpertQueue,
  ExpertAssignment,
  UpdateExpertProfileRequest,
} from '@/types';
import TokenManager from '@/services/TokenManager';

interface ApiChatServiceConfig {
  baseUrl: string;
  timeout: number;
  retryAttempts: number;
}

/**
 * API implementation of ChatService for production use
 * Uses fetch for HTTP requests
 */
export class ApiChatService implements ChatService {
  private baseUrl: string;
  private tokenManager: TokenManager;

  constructor(config: ApiChatServiceConfig) {
    this.baseUrl = config.baseUrl;
    this.tokenManager = TokenManager.getInstance();
  }

  private async makeRequest<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    // 1. Construct the full URL using this.baseUrl and endpoint
    const url = `${this.baseUrl}${endpoint}`;

    // 2. Get the token using this.tokenManager.getToken()
    const token = this.tokenManager.getToken();

    // 3. Set up default headers including 'Content-Type': 'application/json'
    const defaultHeaders = {
      'Content-Type': 'application/json',
      // 4. Add Authorization header with Bearer token if token exists
      ...(token ? { Authorization: `Bearer ${token}` }: {}),
    };

    // 5. Make the fetch request with the provided options
    const request: RequestInit = {
      headers: {
        ...defaultHeaders,
        ...options.headers,
      },
      ...options
    };
    const response = await fetch(url, request);

    // 6. Handle non-ok responses by throwing an error with status and message
    if (!response.ok) {
      let errorMessage = 'HTTP error! status: ${response.status}';
      try {
        const errorData = await response.json();
        errorMessage = errorData.error || errorData.errors?.join(', ') || errorMessage;
      } catch {
        // if response is not json
        errorMessage = response.statusText || errorMessage;
      }
    }
    // 7. Return the parsed JSON response
    if (response.status === 204) {
      return {} as T;
    }

    return await response.json() as T;
  }

  // Conversations
  async getConversations(): Promise<Conversation[]> {
    // 1. Make a request to the appropriate endpoint
    const response = await this.makeRequest<Conversation[]>('/conversations', {
        method: 'GET',
      });
    // 2. Return the array of conversations
    return response;
  }

  async getConversation(_id: string): Promise<Conversation> {
    // 1. Make a request to the appropriate endpoint
    const response = await this.makeRequest<Conversation>(`/conversations/${_id}`, {
        method: 'GET'
      });
    // 2. Return the conversation object
    return response;
  }

  async createConversation(request: CreateConversationRequest): Promise<Conversation> {
    // 1. Make a request to the appropriate endpoint
    const response = await this.makeRequest<Conversation>('/conversations', {
      method: 'POST',
      body: JSON.stringify(request),
    });
    // 2. Return the created conversation object
    return response;
  }

  async updateConversation(id: string, request: UpdateConversationRequest): Promise<Conversation> {
    // SKIP, not currently used by application

    throw new Error('updateConversation method not implemented');
  }

  async deleteConversation(id: string): Promise<void> {
    // SKIP, not currently used by application

    throw new Error('deleteConversation method not implemented');
  }

  // Messages
  async getMessages(conversationId: string): Promise<Message[]> {
    // 1. Make a request to the appropriate endpoint
    const response = await this.makeRequest<Message[]>(`/conversations/${conversationId}/messages`, {
      method: 'GET',
    });
    // 2. Return the array of messages
    return response;
  }

  async sendMessage(request: SendMessageRequest): Promise<Message> {
    // 1. Make a request to the appropriate endpoint
    const response = await this.makeRequest<Message>('/messages', {
      method: 'POST',
      body: JSON.stringify(request),
    });
    // 2. Return the created message object
    return response;
  }

  async markMessageAsRead(messageId: string): Promise<void> {
    // SKIP, not currently used by application
    // TODO: UNCOMMENT IF NEEDED
    // await this.makeRequest<void>(`/messages/${messageId}/read`, { method: 'PUT' });

    throw new Error('markMessageAsRead method not implemented');
  }

  // Expert-specific operations
  async getExpertQueue(): Promise<ExpertQueue> {
    // 1. Make a request to the appropriate endpoint
    const response = await this.makeRequest<ExpertQueue>('/expert/queue', {
      method: 'GET',
    });
    // 2. Return the expert queue object with waitingConversations and assignedConversations
    return response;
  }

  async claimConversation(conversationId: string): Promise<void> {
    // 1. Make a request to the appropriate endpoint
    await this.makeRequest<void>(`/expert/conversations/${conversationId}/claim`, {
      method: 'POST'
    });
    // 2. Return void (no response body expected)
  }

  async unclaimConversation(conversationId: string): Promise<void> {
    // 1. Make a request to the appropriate endpoint
    await this.makeRequest<void>(`/expert/conversations/${conversationId}/unclaim`, {
      method: 'POST',
    });
    // 2. Return void (no response body expected)
  }

  async getExpertProfile(): Promise<ExpertProfile> {
    // 1. Make a request to the appropriate endpoint
    const response = await this.makeRequest<ExpertProfile>('/expert/profile', {
      method: 'GET'
    });
    // 2. Return the expert profile object
    return response;
  }

  async updateExpertProfile(
    request: UpdateExpertProfileRequest
  ): Promise<ExpertProfile> {
    // 1. Make a request to the appropriate endpoint
    const response = await this.makeRequest<ExpertProfile>('/expert/profile', {
      method: 'PUT',
      body: JSON.stringify(request)
    });
    // 2. Return the updated expert profile object
    return response;
  }

  async getExpertAssignmentHistory(): Promise<ExpertAssignment[]> {
    // 1. Make a request to the appropriate endpoint
    const response = await this.makeRequest<ExpertAssignment[]>('/expert/assignments/history', {
      method: 'GET'
    });
    // 2. Return the array of expert assignments
    return response;
  }
}
