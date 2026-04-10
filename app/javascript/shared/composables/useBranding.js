/**
 * Composable for branding-related utilities
 * Provides methods to customize text with installation-specific branding
 */
const INSTALLATION_NAME = 'LYN Soluciones Tec.';

export function useBranding() {
  /**
   * Replaces "Chatwoot" in text with the installation name
   * @param {string} text - The text to process
   * @returns {string} - Text with "Chatwoot" replaced by installation name
   */
  const replaceInstallationName = text => {
    if (!text) return text;
    return text.replace(/Chatwoot/g, INSTALLATION_NAME);
  };

  return {
    replaceInstallationName,
  };
}
