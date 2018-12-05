# coding=utf-8
"""
This code was generated by
\ / _    _  _|   _  _
 | (_)\/(_)(_|\/| |(/_  v1.0.0
      /       /
"""

from twilio.base import deserialize
from twilio.base import values
from twilio.base.instance_context import InstanceContext
from twilio.base.instance_resource import InstanceResource
from twilio.base.list_resource import ListResource
from twilio.base.page import Page


class AuthorizedConnectAppList(ListResource):
    """  """

    def __init__(self, version, account_sid):
        """
        Initialize the AuthorizedConnectAppList

        :param Version version: Version that contains the resource
        :param account_sid: The unique sid that identifies this account

        :returns: twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppList
        :rtype: twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppList
        """
        super(AuthorizedConnectAppList, self).__init__(version)

        # Path Solution
        self._solution = {'account_sid': account_sid, }
        self._uri = '/Accounts/{account_sid}/AuthorizedConnectApps.json'.format(**self._solution)

    def stream(self, limit=None, page_size=None):
        """
        Streams AuthorizedConnectAppInstance records from the API as a generator stream.
        This operation lazily loads records as efficiently as possible until the limit
        is reached.
        The results are returned as a generator, so this operation is memory efficient.

        :param int limit: Upper limit for the number of records to return. stream()
                          guarantees to never return more than limit.  Default is no limit
        :param int page_size: Number of records to fetch per request, when not set will use
                              the default value of 50 records.  If no page_size is defined
                              but a limit is defined, stream() will attempt to read the
                              limit with the most efficient page size, i.e. min(limit, 1000)

        :returns: Generator that will yield up to limit results
        :rtype: list[twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppInstance]
        """
        limits = self._version.read_limits(limit, page_size)

        page = self.page(page_size=limits['page_size'], )

        return self._version.stream(page, limits['limit'], limits['page_limit'])

    def list(self, limit=None, page_size=None):
        """
        Lists AuthorizedConnectAppInstance records from the API as a list.
        Unlike stream(), this operation is eager and will load `limit` records into
        memory before returning.

        :param int limit: Upper limit for the number of records to return. list() guarantees
                          never to return more than limit.  Default is no limit
        :param int page_size: Number of records to fetch per request, when not set will use
                              the default value of 50 records.  If no page_size is defined
                              but a limit is defined, list() will attempt to read the limit
                              with the most efficient page size, i.e. min(limit, 1000)

        :returns: Generator that will yield up to limit results
        :rtype: list[twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppInstance]
        """
        return list(self.stream(limit=limit, page_size=page_size, ))

    def page(self, page_token=values.unset, page_number=values.unset,
             page_size=values.unset):
        """
        Retrieve a single page of AuthorizedConnectAppInstance records from the API.
        Request is executed immediately

        :param str page_token: PageToken provided by the API
        :param int page_number: Page Number, this value is simply for client state
        :param int page_size: Number of records to return, defaults to 50

        :returns: Page of AuthorizedConnectAppInstance
        :rtype: twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppPage
        """
        params = values.of({'PageToken': page_token, 'Page': page_number, 'PageSize': page_size, })

        response = self._version.page(
            'GET',
            self._uri,
            params=params,
        )

        return AuthorizedConnectAppPage(self._version, response, self._solution)

    def get_page(self, target_url):
        """
        Retrieve a specific page of AuthorizedConnectAppInstance records from the API.
        Request is executed immediately

        :param str target_url: API-generated URL for the requested results page

        :returns: Page of AuthorizedConnectAppInstance
        :rtype: twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppPage
        """
        response = self._version.domain.twilio.request(
            'GET',
            target_url,
        )

        return AuthorizedConnectAppPage(self._version, response, self._solution)

    def get(self, connect_app_sid):
        """
        Constructs a AuthorizedConnectAppContext

        :param connect_app_sid: The connect_app_sid

        :returns: twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppContext
        :rtype: twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppContext
        """
        return AuthorizedConnectAppContext(
            self._version,
            account_sid=self._solution['account_sid'],
            connect_app_sid=connect_app_sid,
        )

    def __call__(self, connect_app_sid):
        """
        Constructs a AuthorizedConnectAppContext

        :param connect_app_sid: The connect_app_sid

        :returns: twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppContext
        :rtype: twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppContext
        """
        return AuthorizedConnectAppContext(
            self._version,
            account_sid=self._solution['account_sid'],
            connect_app_sid=connect_app_sid,
        )

    def __repr__(self):
        """
        Provide a friendly representation

        :returns: Machine friendly representation
        :rtype: str
        """
        return '<Twilio.Api.V2010.AuthorizedConnectAppList>'


class AuthorizedConnectAppPage(Page):
    """  """

    def __init__(self, version, response, solution):
        """
        Initialize the AuthorizedConnectAppPage

        :param Version version: Version that contains the resource
        :param Response response: Response from the API
        :param account_sid: The unique sid that identifies this account

        :returns: twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppPage
        :rtype: twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppPage
        """
        super(AuthorizedConnectAppPage, self).__init__(version, response)

        # Path Solution
        self._solution = solution

    def get_instance(self, payload):
        """
        Build an instance of AuthorizedConnectAppInstance

        :param dict payload: Payload response from the API

        :returns: twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppInstance
        :rtype: twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppInstance
        """
        return AuthorizedConnectAppInstance(self._version, payload, account_sid=self._solution['account_sid'], )

    def __repr__(self):
        """
        Provide a friendly representation

        :returns: Machine friendly representation
        :rtype: str
        """
        return '<Twilio.Api.V2010.AuthorizedConnectAppPage>'


class AuthorizedConnectAppContext(InstanceContext):
    """  """

    def __init__(self, version, account_sid, connect_app_sid):
        """
        Initialize the AuthorizedConnectAppContext

        :param Version version: Version that contains the resource
        :param account_sid: The account_sid
        :param connect_app_sid: The connect_app_sid

        :returns: twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppContext
        :rtype: twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppContext
        """
        super(AuthorizedConnectAppContext, self).__init__(version)

        # Path Solution
        self._solution = {'account_sid': account_sid, 'connect_app_sid': connect_app_sid, }
        self._uri = '/Accounts/{account_sid}/AuthorizedConnectApps/{connect_app_sid}.json'.format(**self._solution)

    def fetch(self):
        """
        Fetch a AuthorizedConnectAppInstance

        :returns: Fetched AuthorizedConnectAppInstance
        :rtype: twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppInstance
        """
        params = values.of({})

        payload = self._version.fetch(
            'GET',
            self._uri,
            params=params,
        )

        return AuthorizedConnectAppInstance(
            self._version,
            payload,
            account_sid=self._solution['account_sid'],
            connect_app_sid=self._solution['connect_app_sid'],
        )

    def __repr__(self):
        """
        Provide a friendly representation

        :returns: Machine friendly representation
        :rtype: str
        """
        context = ' '.join('{}={}'.format(k, v) for k, v in self._solution.items())
        return '<Twilio.Api.V2010.AuthorizedConnectAppContext {}>'.format(context)


class AuthorizedConnectAppInstance(InstanceResource):
    """  """

    class Permission(object):
        GET_ALL = "get-all"
        POST_ALL = "post-all"

    def __init__(self, version, payload, account_sid, connect_app_sid=None):
        """
        Initialize the AuthorizedConnectAppInstance

        :returns: twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppInstance
        :rtype: twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppInstance
        """
        super(AuthorizedConnectAppInstance, self).__init__(version)

        # Marshaled Properties
        self._properties = {
            'account_sid': payload['account_sid'],
            'connect_app_company_name': payload['connect_app_company_name'],
            'connect_app_description': payload['connect_app_description'],
            'connect_app_friendly_name': payload['connect_app_friendly_name'],
            'connect_app_homepage_url': payload['connect_app_homepage_url'],
            'connect_app_sid': payload['connect_app_sid'],
            'date_created': deserialize.rfc2822_datetime(payload['date_created']),
            'date_updated': deserialize.rfc2822_datetime(payload['date_updated']),
            'permissions': payload['permissions'],
            'uri': payload['uri'],
        }

        # Context
        self._context = None
        self._solution = {
            'account_sid': account_sid,
            'connect_app_sid': connect_app_sid or self._properties['connect_app_sid'],
        }

    @property
    def _proxy(self):
        """
        Generate an instance context for the instance, the context is capable of
        performing various actions.  All instance actions are proxied to the context

        :returns: AuthorizedConnectAppContext for this AuthorizedConnectAppInstance
        :rtype: twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppContext
        """
        if self._context is None:
            self._context = AuthorizedConnectAppContext(
                self._version,
                account_sid=self._solution['account_sid'],
                connect_app_sid=self._solution['connect_app_sid'],
            )
        return self._context

    @property
    def account_sid(self):
        """
        :returns: The unique sid that identifies this account
        :rtype: unicode
        """
        return self._properties['account_sid']

    @property
    def connect_app_company_name(self):
        """
        :returns: The company name set for this Connect App.
        :rtype: unicode
        """
        return self._properties['connect_app_company_name']

    @property
    def connect_app_description(self):
        """
        :returns: Human readable description of the app
        :rtype: unicode
        """
        return self._properties['connect_app_description']

    @property
    def connect_app_friendly_name(self):
        """
        :returns: A human readable name for the Connect App.
        :rtype: unicode
        """
        return self._properties['connect_app_friendly_name']

    @property
    def connect_app_homepage_url(self):
        """
        :returns: The public URL for this Connect App.
        :rtype: unicode
        """
        return self._properties['connect_app_homepage_url']

    @property
    def connect_app_sid(self):
        """
        :returns: A string that uniquely identifies this app
        :rtype: unicode
        """
        return self._properties['connect_app_sid']

    @property
    def date_created(self):
        """
        :returns: The date this resource was created
        :rtype: datetime
        """
        return self._properties['date_created']

    @property
    def date_updated(self):
        """
        :returns: The date this resource was last updated
        :rtype: datetime
        """
        return self._properties['date_updated']

    @property
    def permissions(self):
        """
        :returns: Permissions authorized to this app
        :rtype: AuthorizedConnectAppInstance.Permission
        """
        return self._properties['permissions']

    @property
    def uri(self):
        """
        :returns: The URI for this resource
        :rtype: unicode
        """
        return self._properties['uri']

    def fetch(self):
        """
        Fetch a AuthorizedConnectAppInstance

        :returns: Fetched AuthorizedConnectAppInstance
        :rtype: twilio.rest.api.v2010.account.authorized_connect_app.AuthorizedConnectAppInstance
        """
        return self._proxy.fetch()

    def __repr__(self):
        """
        Provide a friendly representation

        :returns: Machine friendly representation
        :rtype: str
        """
        context = ' '.join('{}={}'.format(k, v) for k, v in self._solution.items())
        return '<Twilio.Api.V2010.AuthorizedConnectAppInstance {}>'.format(context)
