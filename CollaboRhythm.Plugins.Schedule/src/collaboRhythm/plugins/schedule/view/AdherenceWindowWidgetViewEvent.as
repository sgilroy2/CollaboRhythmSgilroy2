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
package collaboRhythm.plugins.schedule.view
{
	import flash.events.Event;
	
	public class AdherenceWindowWidgetViewEvent extends Event
	{
		public static const ADHERENCE_GROUP_HOUR_CHANGED:String = "AdherenceGroupHourChanged";
		public static const ADHERENCE_GROUP_WINDOW_CHANGED:String = "AdherenceGroupWindowChanged";
		
		private var _widgetAdherenceWindowView:ScheduleGroupClockView;
		
		public function AdherenceWindowWidgetViewEvent(type:String, widgetAdherenceWindowView:ScheduleGroupClockView, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			_widgetAdherenceWindowView = widgetAdherenceWindowView;
		}
		
		public function get widgetAdherenceWindowView():ScheduleGroupClockView
		{
			return _widgetAdherenceWindowView;
		}
	}
}