package collaboRhythm.plugins.cataractMap.model
{
	[Bindable]
	public class CataractMapDataItem
	{
		private var _date:Date;
		private var _isCataract:Boolean;
		private var _densityMapMax:Number;
		private var _densityMap:Vector.<Number>;
		private var _locationMap:Vector.<Boolean>;
		
		public function CataractMapDataItem()
		{
		}

		public function get isCataract():Boolean
		{
			return _isCataract;
		}

		public function set isCataract(value:Boolean):void
		{
			_isCataract = value;
		}

		public function get densityMapMax():Number
		{
			return _densityMapMax;
		}

		public function set densityMapMax(value:Number):void
		{
			_densityMapMax = value;
		}

		public function get densityMap():Vector.<Number>
		{
			return _densityMap;
		}

		public function set densityMap(value:Vector.<Number>):void
		{
			_densityMap = value;
		}

		public function get locationMap():Vector.<Boolean>
		{
			return _locationMap;
		}

		public function set locationMap(value:Vector.<Boolean>):void
		{
			_locationMap = value;
		}

		public function get date():Date
		{
			return _date;
		}

		public function set date(value:Date):void
		{
			_date = value;
		}

	}
}