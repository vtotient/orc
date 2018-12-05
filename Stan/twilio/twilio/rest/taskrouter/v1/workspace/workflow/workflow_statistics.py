# coding=utf-8
"""
This code was generated by
\ / _    _  _|   _  _
 | (_)\/(_)(_|\/| |(/_  v1.0.0
      /       /
"""

from twilio.base import serialize
from twilio.base import values
from twilio.base.instance_context import InstanceContext
from twilio.base.instance_resource import InstanceResource
from twilio.base.list_resource import ListResource
from twilio.base.page import Page


class WorkflowStatisticsList(ListResource):
    """  """

    def __init__(self, version, workspace_sid, workflow_sid):
        """
        Initialize the WorkflowStatisticsList

        :param Version version: Version that contains the resource
        :param workspace_sid: The workspace_sid
        :param workflow_sid: The workflow_sid

        :returns: twilio.rest.taskrouter.v1.workspace.workflow.workflow_statistics.WorkflowStatisticsList
        :rtype: twilio.rest.taskrouter.v1.workspace.workflow.workflow_statistics.WorkflowStatisticsList
        """
        super(WorkflowStatisticsList, self).__init__(version)

        # Path Solution
        self._solution = {'workspace_sid': workspace_sid, 'workflow_sid': workflow_sid, }

    def get(self):
        """
        Constructs a WorkflowStatisticsContext

        :returns: twilio.rest.taskrouter.v1.workspace.workflow.workflow_statistics.WorkflowStatisticsContext
        :rtype: twilio.rest.taskrouter.v1.workspace.workflow.workflow_statistics.WorkflowStatisticsContext
        """
        return WorkflowStatisticsContext(
            self._version,
            workspace_sid=self._solution['workspace_sid'],
            workflow_sid=self._solution['workflow_sid'],
        )

    def __call__(self):
        """
        Constructs a WorkflowStatisticsContext

        :returns: twilio.rest.taskrouter.v1.workspace.workflow.workflow_statistics.WorkflowStatisticsContext
        :rtype: twilio.rest.taskrouter.v1.workspace.workflow.workflow_statistics.WorkflowStatisticsContext
        """
        return WorkflowStatisticsContext(
            self._version,
            workspace_sid=self._solution['workspace_sid'],
            workflow_sid=self._solution['workflow_sid'],
        )

    def __repr__(self):
        """
        Provide a friendly representation

        :returns: Machine friendly representation
        :rtype: str
        """
        return '<Twilio.Taskrouter.V1.WorkflowStatisticsList>'


class WorkflowStatisticsPage(Page):
    """  """

    def __init__(self, version, response, solution):
        """
        Initialize the WorkflowStatisticsPage

        :param Version version: Version that contains the resource
        :param Response response: Response from the API
        :param workspace_sid: The workspace_sid
        :param workflow_sid: The workflow_sid

        :returns: twilio.rest.taskrouter.v1.workspace.workflow.workflow_statistics.WorkflowStatisticsPage
        :rtype: twilio.rest.taskrouter.v1.workspace.workflow.workflow_statistics.WorkflowStatisticsPage
        """
        super(WorkflowStatisticsPage, self).__init__(version, response)

        # Path Solution
        self._solution = solution

    def get_instance(self, payload):
        """
        Build an instance of WorkflowStatisticsInstance

        :param dict payload: Payload response from the API

        :returns: twilio.rest.taskrouter.v1.workspace.workflow.workflow_statistics.WorkflowStatisticsInstance
        :rtype: twilio.rest.taskrouter.v1.workspace.workflow.workflow_statistics.WorkflowStatisticsInstance
        """
        return WorkflowStatisticsInstance(
            self._version,
            payload,
            workspace_sid=self._solution['workspace_sid'],
            workflow_sid=self._solution['workflow_sid'],
        )

    def __repr__(self):
        """
        Provide a friendly representation

        :returns: Machine friendly representation
        :rtype: str
        """
        return '<Twilio.Taskrouter.V1.WorkflowStatisticsPage>'


class WorkflowStatisticsContext(InstanceContext):
    """  """

    def __init__(self, version, workspace_sid, workflow_sid):
        """
        Initialize the WorkflowStatisticsContext

        :param Version version: Version that contains the resource
        :param workspace_sid: The workspace_sid
        :param workflow_sid: The workflow_sid

        :returns: twilio.rest.taskrouter.v1.workspace.workflow.workflow_statistics.WorkflowStatisticsContext
        :rtype: twilio.rest.taskrouter.v1.workspace.workflow.workflow_statistics.WorkflowStatisticsContext
        """
        super(WorkflowStatisticsContext, self).__init__(version)

        # Path Solution
        self._solution = {'workspace_sid': workspace_sid, 'workflow_sid': workflow_sid, }
        self._uri = '/Workspaces/{workspace_sid}/Workflows/{workflow_sid}/Statistics'.format(**self._solution)

    def fetch(self, minutes=values.unset, start_date=values.unset,
              end_date=values.unset, task_channel=values.unset,
              split_by_wait_time=values.unset):
        """
        Fetch a WorkflowStatisticsInstance

        :param unicode minutes: The minutes
        :param datetime start_date: The start_date
        :param datetime end_date: The end_date
        :param unicode task_channel: The task_channel
        :param unicode split_by_wait_time: The split_by_wait_time

        :returns: Fetched WorkflowStatisticsInstance
        :rtype: twilio.rest.taskrouter.v1.workspace.workflow.workflow_statistics.WorkflowStatisticsInstance
        """
        params = values.of({
            'Minutes': minutes,
            'StartDate': serialize.iso8601_datetime(start_date),
            'EndDate': serialize.iso8601_datetime(end_date),
            'TaskChannel': task_channel,
            'SplitByWaitTime': split_by_wait_time,
        })

        payload = self._version.fetch(
            'GET',
            self._uri,
            params=params,
        )

        return WorkflowStatisticsInstance(
            self._version,
            payload,
            workspace_sid=self._solution['workspace_sid'],
            workflow_sid=self._solution['workflow_sid'],
        )

    def __repr__(self):
        """
        Provide a friendly representation

        :returns: Machine friendly representation
        :rtype: str
        """
        context = ' '.join('{}={}'.format(k, v) for k, v in self._solution.items())
        return '<Twilio.Taskrouter.V1.WorkflowStatisticsContext {}>'.format(context)


class WorkflowStatisticsInstance(InstanceResource):
    """  """

    def __init__(self, version, payload, workspace_sid, workflow_sid):
        """
        Initialize the WorkflowStatisticsInstance

        :returns: twilio.rest.taskrouter.v1.workspace.workflow.workflow_statistics.WorkflowStatisticsInstance
        :rtype: twilio.rest.taskrouter.v1.workspace.workflow.workflow_statistics.WorkflowStatisticsInstance
        """
        super(WorkflowStatisticsInstance, self).__init__(version)

        # Marshaled Properties
        self._properties = {
            'account_sid': payload['account_sid'],
            'cumulative': payload['cumulative'],
            'realtime': payload['realtime'],
            'workflow_sid': payload['workflow_sid'],
            'workspace_sid': payload['workspace_sid'],
            'url': payload['url'],
        }

        # Context
        self._context = None
        self._solution = {'workspace_sid': workspace_sid, 'workflow_sid': workflow_sid, }

    @property
    def _proxy(self):
        """
        Generate an instance context for the instance, the context is capable of
        performing various actions.  All instance actions are proxied to the context

        :returns: WorkflowStatisticsContext for this WorkflowStatisticsInstance
        :rtype: twilio.rest.taskrouter.v1.workspace.workflow.workflow_statistics.WorkflowStatisticsContext
        """
        if self._context is None:
            self._context = WorkflowStatisticsContext(
                self._version,
                workspace_sid=self._solution['workspace_sid'],
                workflow_sid=self._solution['workflow_sid'],
            )
        return self._context

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
    def workflow_sid(self):
        """
        :returns: The workflow_sid
        :rtype: unicode
        """
        return self._properties['workflow_sid']

    @property
    def workspace_sid(self):
        """
        :returns: The workspace_sid
        :rtype: unicode
        """
        return self._properties['workspace_sid']

    @property
    def url(self):
        """
        :returns: The url
        :rtype: unicode
        """
        return self._properties['url']

    def fetch(self, minutes=values.unset, start_date=values.unset,
              end_date=values.unset, task_channel=values.unset,
              split_by_wait_time=values.unset):
        """
        Fetch a WorkflowStatisticsInstance

        :param unicode minutes: The minutes
        :param datetime start_date: The start_date
        :param datetime end_date: The end_date
        :param unicode task_channel: The task_channel
        :param unicode split_by_wait_time: The split_by_wait_time

        :returns: Fetched WorkflowStatisticsInstance
        :rtype: twilio.rest.taskrouter.v1.workspace.workflow.workflow_statistics.WorkflowStatisticsInstance
        """
        return self._proxy.fetch(
            minutes=minutes,
            start_date=start_date,
            end_date=end_date,
            task_channel=task_channel,
            split_by_wait_time=split_by_wait_time,
        )

    def __repr__(self):
        """
        Provide a friendly representation

        :returns: Machine friendly representation
        :rtype: str
        """
        context = ' '.join('{}={}'.format(k, v) for k, v in self._solution.items())
        return '<Twilio.Taskrouter.V1.WorkflowStatisticsInstance {}>'.format(context)
