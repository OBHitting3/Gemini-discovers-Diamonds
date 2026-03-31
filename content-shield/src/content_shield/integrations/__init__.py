"""Integrations with third-party content platforms."""

from content_shield.integrations.hubspot import HubSpotIntegration
from content_shield.integrations.mailchimp import MailchimpIntegration
from content_shield.integrations.shopify import ShopifyIntegration
from content_shield.integrations.webhook_generic import GenericWebhookIntegration
from content_shield.integrations.wordpress import WordPressIntegration

__all__ = [
    "GenericWebhookIntegration",
    "WordPressIntegration",
    "HubSpotIntegration",
    "MailchimpIntegration",
    "ShopifyIntegration",
]
