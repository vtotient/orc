# coding=utf-8
"""
This code was generated by
\ / _    _  _|   _  _
 | (_)\/(_)(_|\/| |(/_  v1.0.0
      /       /
"""

from twilio.base import serialize
from twilio.base import values
from twilio.base.instance_resource import InstanceResource
from twilio.base.list_resource import ListResource
from twilio.base.page import Page


class TaskQueuesStatisticsList(ListResource):
    """  """

    def __init__(self, version, workspace_sid):
        """
        Initialize the TaskQueuesStatisticsList

        :param Version version: Version that contains the resource
        :param workspace_sid: The workspace_sid

        :returns: twilio.rest.taskrouter.v1.workspace.task_queue.task_queues_statistics.TaskQueuesStatisticsList
        :rtype: twilio.rest.taskrouter.v1.workspace.task_queue.task_queues_statistics.TaskQueuesStatisticsList
        """
        super(TaskQueuesStatisticsList, self).__init__(version)

        # Path Solution
        self._solution = {'workspace_sid': workspace_sid, }
        self._uri = '/Workspaces/{workspace_sid}/TaskQueues/Statistics'.format(**self._solution)

    def stream(self, end_date=values.unset, friendly_name=values.unset,
               minutes=values.unset, start_date=values.unset,
               task_channel=values.unset, split_by_wait_time=values.unset,
               limit=None, page_size=None):
        """
        Streams TaskQueuesStatisticsInstance records from the API as a generator stream.
        This operation lazily loads records as efficiently as possible until the limit
        is reached.
        The results are returned as a generator, so this operation is memory efficient.

        :param datetime end_date: The end_date
        :param unicode friendly_name: The friendly_name
        :param unicode minutes: The minutes
        :param datetime start_date: The start_date
        :param unicode task_channel: The task_channel
        :param unicode split_by_wait_time: The split_by_wait_time
        :param int limit: Upper limit for the number of records to return. stream()
                          guarantees to never return more than limit.  Default is no limit
        :param int page_size: Number of records to fetch per request, when not set will use
                              the default value of 50 records.  If no page_size is defined
                              but a limit is defined, stream() will attempt to read the
                              limit with the most efficient page size, i.e. min(limit, 1000)

        :returns: Generator that will yield up to limit results
        :rtype: list[twilio.rest.taskrouter.v1.workspace.task_queue.task_queues_statistics.TaskQueuesStatisticsInstance]
        """
        limits = self._version.read_limits(limit, page_size)

        page = self.page(
            end_date=end_date,
            friendly_name=friendly_name,
            minutes=minutes,
            start_date=start_date,
            task_channel=task_channel,
            split_by_wait_time=split_by_wait_time,
            page_size=limits['page_size'],
        )

        return self._version.stream(page, limits['limit'], limits['page_limit'])

    def list(self, end_date=values.unset, friendly_name=values.unset,
             minutes=values.unset, start_date=values.unset,
             task_channel=values.unset, split_by_wait_time=values.unset, limit=None,
             page_size=None):
        """
        Lists TaskQueuesStatisticsInstance records from the API as a list.
        Unlike stream(), this operation is eager and will load `limit` records into
        memory before returning.

        :param datetime end_date: The end_date
        :param unicode friendly_name: The friendly_name
        :param unicode minutes: The minutes
        :param datetime start_date: The start_date
        :param unicode task_channel: The task_channel
        :param unicode split_by_wait_time: The split_by_wait_time
        :param int limit: Upper limit for the number of records to return. list() guarantees
                          never to return more than limit.  Default is no limit
        :param int page_size: Number of records to fetch per request, when not set will use
                              the default value of 50 records.  If no page_size is defined
                              but a limit is defined, list() will attempt to read the limit
                              with the most efficient page size, i.e. min(limit, 1000)

        :returns: Generator that will yield up to limit results
        :rtype: list[twilio.rest.taskrouter.v1.workspace.task_queue.task_queues_statistics.TaskQueuesStatisticsInstance]
        """
        return list(self.stream(
            end_date=end_date,
            friendly_name=friendly_name,
            minutes=minutes,
            start_date=start_date,
            task_channel=task_channel,
            split_by_wait_time=split_by_wait_time,
            limit=limit,
            page_size=page_size,
        ))

    def page(self, end_date=values.unset, friendly_name=values.unset,
             minutes=values.unset, start_date=values.unset,
             task_channel=values.unset, split_by_wait_time=values.unset,
             page_token=values.unset, page_number=values.unset,
             page_size=values.unset):
        """
        Retrieve a single page of TaskQueuesStatisticsInstance records from the API.
        Request is executed immediately

        :param datetime end_date: The end_date
        :param unicode friendly_name: The friendly_name
        :param unicode minutes: The minutes
        :param datetime start_date: The start_date
        :param unicode task_channel: The task_channel
        :param unicode split_by_wait_time: The split_by_wait_time
        :param str page_token: PageToken provided by the API
        :param int page_number: Page Number, this value is simply for client state
        :param int page_size: Number of records to return, defaults to 50

        :returns: Page of TaskQueuesStatisticsInstance
        :rtype: twilio.rest.taskrouter.v1.workspace.task_queue.task_queues_statistics.TaskQueuesStatisticsPage
        """
        params = values.of({
            'EndDate': serialize.iso8601_datetime(end_date),
            'FriendlyName': friendly_name,
            'Minutes': minutes,
            'StartDate': serialize.iso8601_datetime(start_date),
            'TaskChannel': task_channel,
            'SplitByWaitTime': split_by_wait_time,
            'PageToken': page_token,
            'Page': page_number,
            'PageSize': page_size,
        })

        response = self._version.page(
            'GET',
            self._uri,
            params=params,
        )

        return TaskQueuesStatisticsPage(self._version, response, self._solution)

    def get_page(self, target_url):
        """
        Retrieve a specific page of TaskQueuesStatisticsInstance records from the API.
        Request is executed immediately

        :param str target_url: API-generated URL for the requested results page

        :returns: Page of TaskQueuesStatisticsInstance
        :rtype: twilio.rest.taskrouter.v1.workspace.task_queue.task_queues_statistics.TaskQueuesStatisticsPage
        """
        response = self._version.domain.twilio.request(
            'GET',
            target_url,
        )

        return TaskQueuesStatisticsPage(self._version, response, self._solution)

    def __repr__(self):
        """
        Provide a friendly representation

        :returns: Machine friendly representation
        :rtype: str
        """
        return '<Twilio.Taskrouter.V1.TaskQueuesStatisticsList>'


class TaskQueuesStatisticsPage(Page):
    """  """

    def __init__(self, version, response, solution):
        """
        Initialize the TaskQueuesStatisticsPage

        :param Version version: Version that contains the resource
        :param Response response: Response from the API
        :param workspace_sid: The workspace_sid

        :returns: twilio.rest.taskrouter.v1.workspace.task_queue.task_queues_statistics.TaskQueuesStatisticsPage
        :rtype: twilio.rest.taskrouter.v1.workspace.task_queue.task_queues_statistics.TaskQueuesStatisticsPage
        """
        super(TaskQueuesStatisticsPage, self).__init__(version, response)

        # Path Solution
        self._solution = solution

    def get_instance(self, payload):
        """
        Build an instance of TaskQueuesStatisticsInstance

        :param dict payload: Payload response from the API

        :returns: twilio.rest.taskrouter.v1.workspace.task_queue.task_queues_statistics.TaskQueuesStatisticsInstance
        :rtype: twilio.rest.taskrouter.v1.workspace.task_queue.task_queues_statistics.TaskQueuesStatisticsInstance
        """
        return TaskQueuesStatisticsInstance(
            self._version,
            payload,
            workspace_sid=self._solution['workspace_sid'],
        )

    def __repr__(self):
        """
        Provide a friendly representation

        :returns: Machine friendly representation
        :rtype: str
        """
        return '<Twilio.Taskrouter.V1.TaskQueuesStatisticsPage>'


class TaskQueuesStatisticsInstance(InstanceResource):
    """  """

    def __init__(self, version, payload, workspace_sid):
        """
        Initialize the TaskQueuesStatisticsInstance

        :returns: twilio.rest.taskrouter.v1.workspace.task_queue.task_queues_statistics.TaskQueuesStatisticsInstance
        :rtype: twilio.rest.taskrouter.v1.workspace.task_queue.task_queues_statistics.TaskQueuesStatisticsInstance
        """
        super(TaskQueuesStatisticsInstance, self).__init__(version)

        # Marshaled Properties
        self._properties = {
            'account_sid': payload['account_sid'],
            'cumulative': payload['cumulative'],
            'realtime': payload['realtime'],
            'task_queue_sid': payload['task_queue_sid'],
            'workspace_sid': payload['workspace_sid'],
        }

        # Context
        self._context = None
        self._solution = {'workspace_sid': workspace_sid, }

    @property
    def account_sid(self):
        """
        :returns: The account_sid
        :rtype: unicode
        """
        return self._properties['account_sid']

    @property
    def cumulative(self):
        """
        :returns: The cumulative
        :rtype: dict
        """
        return self._properties['cumulative']

    @property
    def realtime(self):
        """
        :returns: The realtime
        :rtype: dict
        """
        return self._properties['realtime']

    @property
    def task_queue_sid(self):
        """
        :returns: The task_queue_sid
        :rtype: unicode
        """
        return self._properties['task_queue_sid']

    @property
    def workspace_sid(self):
        """
        :returns: The workspace_sid
        :rtype: unicode
        """
        return self._properties['workspace_sid']

    def __repr__(self):
        """
        Provide a friendly representation

        :returns: Machine friendly representation
        :rtype: str
        """
        return '<Twilio.Taskrouter.V1.TaskQueuesStatisticsInstance>'
