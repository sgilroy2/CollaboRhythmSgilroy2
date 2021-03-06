/**
 * Copyright 2011 John Moore, Scott Gilroy
 *
 * This file is part of CollaboRhythm.
 *
 * CollaboRhythm is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation, either version 2 of the License, or (at your option) any later
 * version.
 *
 * CollaboRhythm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with CollaboRhythm.  If not, see
 * <http://www.gnu.org/licenses/>.
 */
package collaboRhythm.core.controller.apps
{

    import castle.flexbridge.reflection.ReflectionUtils;

    import collaboRhythm.plugins.problems.controller.ProblemsAppController;
    import collaboRhythm.shared.apps.allergies.controller.AllergiesAppController;
    import collaboRhythm.shared.apps.bloodPressureAgent.controller.BloodPressureAgentAppController;
    import collaboRhythm.shared.apps.familyHistory.controller.FamilyHistoryAppController;
    import collaboRhythm.shared.apps.genetics.controller.GeneticsAppController;
    import collaboRhythm.shared.apps.imaging.controller.ImagingAppController;
    import collaboRhythm.shared.apps.immunizations.controller.ImmunizationsAppController;
    import collaboRhythm.shared.apps.labs.controller.LabsAppController;
    import collaboRhythm.shared.apps.procedures.controller.ProceduresAppController;
    import collaboRhythm.shared.apps.socialHistory.controller.SocialHistoryAppController;
    import collaboRhythm.shared.apps.vitals.controller.VitalsAppController;
    import collaboRhythm.shared.controller.apps.AppControllerInfo;
    import collaboRhythm.shared.controller.apps.WorkstationAppControllerBase;
    import collaboRhythm.shared.controller.apps.WorkstationAppControllerFactory;
    import collaboRhythm.shared.controller.apps.WorkstationAppEvent;
    import collaboRhythm.shared.model.*;
    import collaboRhythm.shared.model.services.IComponentContainer;
    import collaboRhythm.shared.model.settings.AppGroupDescriptor;
    import collaboRhythm.shared.model.settings.Settings;

    import com.theory9.data.types.OrderedMap;

    import flash.net.registerClassAlias;
    import flash.utils.getQualifiedClassName;

    import mx.collections.ArrayCollection;
    import mx.core.IVisualElementContainer;
    import mx.core.UIComponent;
    import mx.logging.ILogger;
    import mx.logging.Log;

    /**
	 * Responsible for creating the collection of workstation apps and adding them to the parent container.
	 *
	 */
	public class AppControllersMediatorBase
	{
		protected var _widgetParentContainer:IVisualElementContainer;
		protected var _scheduleWidgetParentContainer:IVisualElementContainer;
		private var _fullParentContainer:IVisualElementContainer;
		private var _settings:Settings;
		private var _workstationApps:OrderedMap;
		private var _collaborationRoomNetConnectionService:CollaborationRoomNetConnectionService;
		private var _factory:WorkstationAppControllerFactory;
		private var _componentContainer:IComponentContainer;
		private static const STANDARD_APP_GROUP:String = "standard";
		private static const CUSTOM_APP_GROUP:String = "custom";
		private var _currentAppGroup:AppGroup;
		private var _appGroups:OrderedMap; // of AppGroup
		private var dynamicAppDictionary:OrderedMap;
		protected var logger:ILogger;
		private var _currentFullView:String;

		public function AppControllersMediatorBase(
			widgetParentContainer:IVisualElementContainer,
			scheduleWidgetParentContainer:IVisualElementContainer,
			fullParentContainer:IVisualElementContainer,
			settings:Settings,
//			healthRecordService:CommonHealthRecordService,
//			collaborationRoomNetConnectionService:CollaborationRoomNetConnectionService,
			componentContainer:IComponentContainer
		)
		{
			logger = Log.getLogger(getQualifiedClassName(this).replace("::", "."));
			_widgetParentContainer = widgetParentContainer;
			_scheduleWidgetParentContainer = scheduleWidgetParentContainer;
			_fullParentContainer = fullParentContainer;
			_settings = settings;
//			_healthRecordService = healthRecordService;
//			_collaborationRoomNetConnectionService = collaborationRoomNetConnectionService;
			_componentContainer = componentContainer;

//			_collaborationRoomNetConnectionService.netConnection.client.showFullView = showFullView;
		}

		protected function get componentContainer():IComponentContainer
		{
			return _componentContainer;
		}

		public function get fullParentContainer():IVisualElementContainer
		{
			return _fullParentContainer;
		}

		public function set fullParentContainer(value:IVisualElementContainer):void
		{
			_fullParentContainer = value;
			if (_factory)
				_factory.fullParentContainer = value;
		}

		public function get widgetParentContainer():IVisualElementContainer
		{
			return _widgetParentContainer;
		}

		public function set widgetParentContainer(value:IVisualElementContainer):void
		{
			_widgetParentContainer = value;
			if (_factory)
				_factory.widgetParentContainer = value;
		}

		public function get workstationApps():OrderedMap
		{
			return _workstationApps;
		}

		/**
		 * Creates and starts (shows widgets for) all the apps for CollaboRhythm.Workstation. Apps in the first group
		 * in settings.appGroups (if any) are put in the widgetParentContainer. Apps in the second group (if any) are
		 * put in scheduleWidgetParentContainer.
		 * @param user The user to initialize the apps for.
		 */
		public function createAndStartApps(activeAccount:Account, activeRecordAccount:Account):void
		{
			initializeForAccount(activeAccount, activeRecordAccount);

			// TODO: find the groups by id instead of index
			createAppsForGroup(0);
			_factory.widgetParentContainer = _scheduleWidgetParentContainer;
			createAppsForGroup(1);

			showAllWidgets();
		}

        // TODO: Now that a base class has been created, change createAndStartApps to be an override
        public function createTabletApps(activeAccount:Account, activeRecordAccount:Account):void
        {
            initializeForAccount(activeAccount, activeRecordAccount);

			// TODO: find the groups by id instead of index
			createAppsForGroup(0);
            _factory.widgetParentContainer = _scheduleWidgetParentContainer;
			createAppsForGroup(1);

			showAllWidgets();
        }

		/**
		 * Creates all the apps for CollaboRhythm.Mobile. Apps in the first group in settings.appGroups (if any) are
		 * created and initialized, ready for navigation. If no groups are specified in settings.appGroups, a group
		 * is automatically created from all dynamic apps.
		 * @param user The user to initialize the apps for.
		 */
		public function createMobileApps(activeAccount:Account, activeRecordAccount:Account):void
		{
			initializeForAccount(activeAccount, activeRecordAccount);
			if (_settings.appGroups && _settings.appGroups.length > 0)
				createAppsForGroup(0);
			else
				createDynamicApps();
		}

		private function createAppsForGroup(groupIndex:int):void
		{
			// TODO: find another way to load the static app controller classes dynamically
			// the following "force" variables exist only to ensure that subsequent calls to getClassByAlias() will work
			var forceProblems:ProblemsAppController;
			var forceProcedures:ProceduresAppController;
			var forceImmunizations:ImmunizationsAppController;
			var forceAllergies:AllergiesAppController;
			var forceGenetics:GeneticsAppController;
			var forceFamilyHistory:FamilyHistoryAppController;
			var forceSocialHistory:SocialHistoryAppController;
			var forceVitals:VitalsAppController;
			var forceLabs:LabsAppController;
			var forceImaging:ImagingAppController;
			var forceBloodPressureAgent:BloodPressureAgentAppController;

			if (_settings.appGroups && _settings.appGroups.length > groupIndex)
			{
				var appGroupDescriptor:AppGroupDescriptor = _settings.appGroups[groupIndex] as AppGroupDescriptor;

				initializeAppGroup(appGroupDescriptor.id);

				for each (var appDescriptor:String in appGroupDescriptor.appDescriptors)
				{
					var appClass:Class = dynamicAppDictionary.getValueByKey(appDescriptor);

					if (appClass == null)
					{
						try
						{
							appClass = ReflectionUtils.getClassByName(appDescriptor.replace("::", "."));
						}
						catch(e:Error)
						{
							logger.error("Error attempting to getClassByAlias: " + e.message);
						}
					}

					if (appClass)
						createApp(appClass);
					else
						logger.error("Failed to get instance of app controller class: " + appDescriptor + " for app group #" + groupIndex + " (" + appGroupDescriptor.id + ")");
				}
			}
		}

		private function showAllWidgets():void
		{
			var app:WorkstationAppControllerBase;
			for each (app in _workstationApps.values())
			{
				app.showWidget();
			}
		}

		private function initializeAppGroup(appGroupId:String):void
		{
			_currentAppGroup = new AppGroup();
			_currentAppGroup.id = appGroupId;
			_appGroups.addKeyValue(appGroupId, _currentAppGroup);
		}

		private function createDynamicApps():void
		{
			logger.warn("Warning: no app groups specified in settings; creating standard app group from all dynamic apps");

			initializeAppGroup(STANDARD_APP_GROUP);

			var infoArray:Array = componentContainer.resolveAll(AppControllerInfo);

			infoArray = AppControllersSorter.orderAppsByInitializationOrderConstraints(infoArray);

			for each (var info:AppControllerInfo in infoArray)
			{
				if (info.groupWidgetViewWithSchedule)
					_factory.widgetParentContainer = _scheduleWidgetParentContainer;
				else
					_factory.widgetParentContainer = _widgetParentContainer;

				createApp(info.appControllerClass);
			}
		}

		public function get numDynamicApps():int
		{
			var infoArray:Array = componentContainer.resolveAll(AppControllerInfo);
			return infoArray.length;
		}

		private function initializeForAccount(activeAccount:Account, activeRecordAccount:Account):void
		{
			closeApps();

			_appGroups = new OrderedMap();
			initializeDynamicAppLookup();
			_workstationApps = new OrderedMap();
			_factory = new WorkstationAppControllerFactory();
			_factory.widgetParentContainer = _widgetParentContainer;
			_factory.fullParentContainer = _fullParentContainer;
//			_factory.healthRecordService = _healthRecordService;
//			_factory.collaborationRoomNetConnectionServiceProxy = _collaborationRoomNetConnectionService.createProxy();
			_factory.isWorkstationMode = _settings.isWorkstationMode;
            _factory.activeAccount = activeAccount;
            _factory.activeRecordAccount = activeRecordAccount;
            _factory.settings = _settings;
            _factory.componentContainer = _componentContainer;
		}

		private function initializeDynamicAppLookup():void
		{
			dynamicAppDictionary = new OrderedMap();

			var infoArray:Array = componentContainer.resolveAll(AppControllerInfo);

			for each (var info:AppControllerInfo in infoArray)
			{
				dynamicAppDictionary.addKeyValue(info.appId, info.appControllerClass);
				registerClassAlias(info.appId.replace("::", "."), info.appControllerClass)
			}
		}

		public function reloadUserData():void
		{
			for each (var app:WorkstationAppControllerBase in _workstationApps.values())
			{
				app.reloadUserData();
			}
		}

		public function createApp(appClass:Class, appName:String=null):WorkstationAppControllerBase
		{
			var app:WorkstationAppControllerBase = _factory.createApp(appClass, appName);
			if (_currentAppGroup)
				_currentAppGroup.apps.push(app);
			appName = app.name;

			if (appName == null)
				throw new Error("appName must not be null; app controller should override defaultName property");

			app.addEventListener(WorkstationAppEvent.SHOW_FULL_VIEW, showFullViewHandler);
			_workstationApps.addKeyValue(appName, app);
			return app;
		}

		private function showFullViewHandler(event:WorkstationAppEvent):void
		{
			if (event.workstationAppController == null)
			{
				// TODO: use constant instead of magic string
				showFullView(event.applicationName, "local");
			}
			else
			{
				showFullViewResolved(event.workstationAppController, "local");
			}
		}

		public function showFullView(applicationName:String, source:String="local"):void
		{
			var workstationAppController:WorkstationAppControllerBase = _workstationApps.getValueByKey(applicationName);
			if (workstationAppController != null)
				showFullViewResolved(workstationAppController, source);
		}

		private function showFullViewResolved(workstationAppController:WorkstationAppControllerBase, source:String):void
		{
			// TODO: use app id instead of name
			currentFullView = workstationAppController.name;

			for each (var app:WorkstationAppControllerBase in _workstationApps.values())
			{
				if (app != workstationAppController)
					app.hideFullView();
				else
					app.showFullView(null);
			}

			(_widgetParentContainer as UIComponent).validateNow();

//			if (source == "local")
//			{
//				_collaborationRoomNetConnectionService.netConnection.call("showFullView", null, _collaborationRoomNetConnectionService.localUserName, workstationAppController.name);
//			}
		}

		public function get currentFullView():String
		{
			return _currentFullView;
		}

		public function set currentFullView(currentFullView:String):void
		{
			_currentFullView = currentFullView;
		}

		public function closeApps():void
		{
			if (_workstationApps != null)
			{
				for each (var app:WorkstationAppControllerBase in _workstationApps.values())
				{
					app.close();
				}
			}

			_currentFullView = null;
			_currentAppGroup = null;
			_appGroups = null;
		}

		/**
		 * Updates settings.appGroups with AppGroupDescriptor instances based on the AppGroup instances currently in use.
		 */
		public function updateAppGroupSettings():void
		{
			_settings.appGroups = new ArrayCollection();

			if (_appGroups)
			{
				for each (var appGroup:AppGroup in _appGroups.values())
				{
					_settings.appGroups.addItem(new AppGroupDescriptor(appGroup.id,
																	   appGroup.appDescriptors));
				}
			}
		}
	}
}
