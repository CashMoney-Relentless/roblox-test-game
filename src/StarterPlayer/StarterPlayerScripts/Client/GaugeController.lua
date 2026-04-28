local GaugeController = {}

local Widgets = require(script.Parent:WaitForChild("Widgets"))

function GaugeController.new()
	local self = {
		_gauges = {},
	}
	setmetatable(self, { __index = GaugeController })

	function self:Register(id, gauge)
		self._gauges[id] = gauge
	end

	function self:Set(id, value)
		local g = self._gauges[id]
		if g then
			g:Set(value)
		end
	end

	function self:UpdateFromState(snapshot)
		if not snapshot then return end
		local r = snapshot.Reactor
		local c = snapshot.Coolant
		local f = snapshot.Feedwater
		local s = snapshot.Steam

		if r then
			self:Set("ReactorPower", r.ReactorPowerPct)
			self:Set("CoreTemp", r.CoreTemp)
			self:Set("CorePressure", r.CorePressure)
			self:Set("CoreWater", r.CoreWater)
			self:Set("NeutronFlux", r.NeutronFlux * 100)
			self:Set("RodHeight", r.RodHeight)
			self:Set("MeltdownRisk", r.MeltdownRisk)
			self:Set("DecayHeat", r.DecayHeat)
		end
		if c then
			self:Set("FlowA", c.FlowA)
			self:Set("FlowB", c.FlowB)
			self:Set("LoopALevel", c.LoopALevel)
			self:Set("LoopBLevel", c.LoopBLevel)
			self:Set("InletTemp", c.InletTemp)
			self:Set("OutletTemp", c.OutletTemp)
			self:Set("OutletPressure", c.OutletPressure)
			self:Set("PumpA", c.PumpASpeed)
			self:Set("PumpB", c.PumpBSpeed)
		end
		if f then
			self:Set("HotwellLevel", f.HotwellLevel)
			self:Set("DeaeratorALevel", f.DeaeratorALevel)
			self:Set("DeaeratorBLevel", f.DeaeratorBLevel)
			self:Set("DeaeratorATemp", f.DeaeratorATemp)
			self:Set("DeaeratorBTemp", f.DeaeratorBTemp)
			self:Set("FeedPumpA", f.FeedPumpASpeed)
			self:Set("FeedPumpB", f.FeedPumpBSpeed)
			self:Set("CondPumpA", f.CondPumpASpeed)
			self:Set("CondPumpB", f.CondPumpBSpeed)
		end
		if s then
			self:Set("SteamPressure", s.SteamPressure)
			self:Set("MainSteamValve", s.MainSteamValve)
			self:Set("BypassValve", s.BypassValve)
			self:Set("TurbineRPM", s.TurbineRPM)
			self:Set("GeneratorMW", s.GeneratorMW)
			self:Set("TransformerLoad", s.TransformerLoad)
			self:Set("Vibration", s.Vibration)
		end
	end

	return self
end

return GaugeController
