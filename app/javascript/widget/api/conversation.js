import endPoints from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

const createConversationAPI = async content => {
  const urlData = endPoints.createConversation(content);
  return API.post(urlData.url, urlData.params);
};

const sendMessageAPI = async (content, replyTo = null) => {
  const urlData = endPoints.sendMessage(content, replyTo);
  return API.post(urlData.url, urlData.params);
};

const sendAttachmentAPI = async (attachment, replyTo = null) => {
  const urlData = endPoints.sendAttachment(attachment, replyTo);
  return API.post(urlData.url, urlData.params);
};

const getMessagesAPI = async ({ before, after }) => {
  const urlData = endPoints.getConversation({ before, after });
  return API.get(urlData.url, { params: urlData.params });
};

const getConversationAPI = async () => {
  return API.get(`/api/v1/widget/conversations${window.location.search}`);
};

const toggleTyping = async ({ typingStatus }) => {
  return API.post(
    `/api/v1/widget/conversations/toggle_typing${window.location.search}`,
    { typing_status: typingStatus }
  );
};

const setUserLastSeenAt = async ({ lastSeen }) => {
  return API.post(
    `/api/v1/widget/conversations/update_last_seen${window.location.search}`,
    { contact_last_seen_at: lastSeen }
  );
};
const sendEmailTranscript = async () => {
  return API.post(
    `/api/v1/widget/conversations/transcript${window.location.search}`
  );
};
const toggleStatus = async () => {
  return API.get(
    `/api/v1/widget/conversations/toggle_status${window.location.search}`
  );
};

const setCustomAttributes = async customAttributes => {
  return API.post(
    `/api/v1/widget/conversations/set_custom_attributes${window.location.search}`,
    {
      custom_attributes: customAttributes,
    }
  );
};

const deleteCustomAttribute = async customAttribute => {
  return API.post(
    `/api/v1/widget/conversations/destroy_custom_attributes${window.location.search}`,
    {
      custom_attribute: [customAttribute],
    }
  );
};

const parseFilenameFromContentDisposition = disposition => {
  if (!disposition) return null;
  const match = disposition.match(/filename="?([^";]+)"?/i);
  return match ? match[1] : null;
};

const exportConversation = async format => {
  const separator = window.location.search ? '&' : '?';
  const response = await API.get(
    `/api/v1/widget/conversations/export${window.location.search}${separator}format_type=${format}`,
    { responseType: 'blob' }
  );

  const contentType =
    response.headers['content-type'] || 'application/octet-stream';
  const blob = new Blob([response.data], { type: contentType });
  const downloadUrl = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = downloadUrl;
  link.download =
    parseFilenameFromContentDisposition(
      response.headers['content-disposition']
    ) || `conversation.${format}`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(downloadUrl);
};

export {
  createConversationAPI,
  sendMessageAPI,
  getConversationAPI,
  getMessagesAPI,
  sendAttachmentAPI,
  toggleTyping,
  setUserLastSeenAt,
  sendEmailTranscript,
  toggleStatus,
  setCustomAttributes,
  deleteCustomAttribute,
  exportConversation,
};
