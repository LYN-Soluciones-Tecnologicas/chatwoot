/* global axios */
import ApiClient from './ApiClient';

class ConversationApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  getLabels(conversationID) {
    return axios.get(`${this.url}/${conversationID}/labels`);
  }

  updateLabels(conversationID, labels) {
    return axios.post(`${this.url}/${conversationID}/labels`, { labels });
  }

  pauseBot(conversationID) {
    return axios.post(`${this.url}/${conversationID}/pause_bot`);
  }

  resumeBot(conversationID) {
    return axios.post(`${this.url}/${conversationID}/resume_bot`);
  }
}

export default new ConversationApi();
