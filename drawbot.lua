-- Drawbot by ShadyRetard

local DRAWBOT_PAINT_ENABLE_CB = gui.Checkbox(gui.Reference("MISC", "AUTOMATION", "Other"), "DRAWBOT_PAINT_ENABLE_CB", "Drawbot Editor", true);
local DRAWBOT_PREVIEW_KB = gui.Keybox(gui.Reference("MISC", "AUTOMATION", "Other"), "DRAWBOT_PREVIEW_KB", "Preview key", 0);
local DRAWBOT_DRAW_KB = gui.Keybox(gui.Reference("MISC", "AUTOMATION", "Other"), "DRAWBOT_DRAW_KB", "Drawing key", 0);
local SCALE_SL = gui.Slider(gui.Reference("MISC", "AUTOMATION", "Other"), "DRAWBOT_SCALE_SL", "Scale", 100, 1, 1000);
local INACCURACY_SL = gui.Slider(gui.Reference("MISC", "AUTOMATION", "Other"), "DRAWBOT_INACCURACY_SL", "Inaccuracy % max", 30, 0, 100);

local EDITOR_POSITION_X, EDITOR_POSITION_Y = 50, 50;
local EDITOR_SIZE_X, EDITOR_SIZE_Y = 400, 400;
local CLEAR_TEXT_W, CLEAR_TEXT_H;
local DRAW_DISTANCE = 1000;

local drawing_center_x, drawing_center_y, drawing_center_z;
local va_x, va_y, va_z;
local center_va_x, center_va_y, center_va_z;
local show, pressed = false, true;
local drawing = {};
local is_dragging = false;
local is_resizing = false;
local is_shooting = false;
local dragging_offset_x, dragging_offset_y;
local current_shoot_index;
local base_inaccuracy;

function drawEditorHandler()
	show = DRAWBOT_PAINT_ENABLE_CB:GetValue();

	if input.IsButtonPressed(gui.GetValue("msc_menutoggle")) then
		pressed = not pressed;
	end

	local mouse_x, mouse_y = input.GetMousePos();
	local show_editor = show == true and pressed == true;

	CLEAR_TEXT_W, CLEAR_TEXT_H = draw.GetTextSize("CLEAR");
	CLEAR_TEXT_H = CLEAR_TEXT_H + 10;

	if (show_editor == true) then
		drawEditor(mouse_x, mouse_y);
	end

	local left_mouse_down = input.IsButtonDown(1);
	local right_mouse_down = input.IsButtonDown(2);
	local draw_key_down = DRAWBOT_DRAW_KB:GetValue() ~= 0 and input.IsButtonDown(DRAWBOT_DRAW_KB:GetValue());
	local preview_key_down = DRAWBOT_PREVIEW_KB:GetValue() ~= 0 and input.IsButtonDown(DRAWBOT_PREVIEW_KB:GetValue());

	if (draw_key_down == true and is_shooting == false) then
		is_shooting = true;
	end

	if (is_shooting == true and draw_key_down == false) then
		is_shooting = false;
		current_shoot_index = nil;
		center_va_x, center_va_y, center_va_z = nil, nil, nil;
		base_inaccuracy = 0;
	end

	if (show_editor == true and is_dragging == true and left_mouse_down == false) then
		is_dragging = false;
		dragging_offset_x = 0;
		dragging_offset_y = 0;
	end

	if (show_editor == true and is_resizing == true and left_mouse_down == false) then
		is_resizing = false;
	end

	if (show_editor == true and left_mouse_down) then
		leftMouseHandler(mouse_x, mouse_y);
	end

	if (show_editor == true and right_mouse_down) then
		rightMouseHandler(mouse_x, mouse_y);
	end

	if (va_x ~= nil and preview_key_down) then
		local local_player = entities.GetLocalPlayer();
		local targets = getTargetLocations(local_player);

		if (targets == nil) then
			return;
		end

		for i=1, #targets do
			local target = targets[i];
			local wx, wy = client.WorldToScreen(target.x, target.y, target.z);
			if (wx ~= nil and wy ~= nil) then
				if (current_shoot_index == i) then
					draw.Color(0, 255, 0, 255);
				else
					draw.Color(0, 0, 0, 255);
				end

				draw.FilledRect(wx-3, wy-3, wx+3, wy+3);
			end
		end
	end
end

function drawEditor(mouse_x, mouse_y)
	-- Header
	draw.Color(gui.GetValue("clr_gui_window_header"));
	draw.FilledRect(EDITOR_POSITION_X, EDITOR_POSITION_Y, EDITOR_POSITION_X + EDITOR_SIZE_X, EDITOR_POSITION_Y + CLEAR_TEXT_H);

	draw.Color(gui.GetValue("clr_gui_window_logo1"));
	draw.Text(EDITOR_POSITION_X + 5, EDITOR_POSITION_Y + 5, "Drawing Editor");

	if (mouse_x >= EDITOR_POSITION_X + EDITOR_SIZE_X - CLEAR_TEXT_W - 10 and mouse_x <= EDITOR_POSITION_X + EDITOR_SIZE_X and mouse_y >= EDITOR_POSITION_Y and mouse_y <= EDITOR_POSITION_Y + CLEAR_TEXT_H) then
		draw.Color(gui.GetValue("clr_gui_window_header_tab1"));
	else
		draw.Color(gui.GetValue("clr_gui_window_header_tab2"));
	end
	draw.FilledRect(EDITOR_POSITION_X + EDITOR_SIZE_X - CLEAR_TEXT_W - 20, EDITOR_POSITION_Y, EDITOR_POSITION_X + EDITOR_SIZE_X, EDITOR_POSITION_Y + CLEAR_TEXT_H);

	draw.Color(gui.GetValue("clr_gui_window_header_tab1"));
	draw.FilledRect(EDITOR_POSITION_X, EDITOR_POSITION_Y + CLEAR_TEXT_H, EDITOR_POSITION_X + EDITOR_SIZE_X, EDITOR_POSITION_Y + CLEAR_TEXT_H + 6);

	draw.Color(255,255,255,255);
	draw.Text(EDITOR_POSITION_X + EDITOR_SIZE_X - CLEAR_TEXT_W - 10, EDITOR_POSITION_Y + 5, "CLEAR");

	draw.FilledRect(EDITOR_POSITION_X, EDITOR_POSITION_Y + CLEAR_TEXT_H + 3, EDITOR_POSITION_X + EDITOR_SIZE_X, EDITOR_POSITION_Y + EDITOR_SIZE_Y + CLEAR_TEXT_H + 3);

	draw.Color(0,0,0,100);
	draw.FilledRect(EDITOR_POSITION_X + EDITOR_SIZE_X - 5, EDITOR_POSITION_Y + CLEAR_TEXT_H + 3 + EDITOR_SIZE_Y + 5, EDITOR_POSITION_X + EDITOR_SIZE_X + 5, EDITOR_POSITION_Y + CLEAR_TEXT_H + 3 + EDITOR_SIZE_Y + 10);
	draw.FilledRect(EDITOR_POSITION_X + EDITOR_SIZE_X + 5, EDITOR_POSITION_Y + CLEAR_TEXT_H + 3 + EDITOR_SIZE_Y - 5, EDITOR_POSITION_X + EDITOR_SIZE_X + 10, EDITOR_POSITION_Y + CLEAR_TEXT_H + 3 + EDITOR_SIZE_Y + 10);

	draw.Color(0,0,0,255);
	for i=1, #drawing do
		local point = drawing[i];
		draw.RoundedRectFill(EDITOR_POSITION_X + point.x, EDITOR_POSITION_Y + point.y, EDITOR_POSITION_X + point.x, EDITOR_POSITION_Y + point.y);
	end
end

function leftMouseHandler(mouse_x, mouse_y)
	if (is_dragging == true) then
		EDITOR_POSITION_X = mouse_x - dragging_offset_x;
		EDITOR_POSITION_Y = mouse_y - dragging_offset_y;
		return;
	end

	if (is_resizing == true) then
		local new_size_x = mouse_x - 10 - EDITOR_POSITION_X;
		if (new_size_x >= 200) then
			EDITOR_SIZE_X = new_size_x;
		end

		local new_size_y = mouse_y - 10 - EDITOR_POSITION_Y - CLEAR_TEXT_H - 3;
		if (new_size_y >= 200) then
			EDITOR_SIZE_Y = new_size_y;
		end

		return;
	end

	if (mouse_x >= EDITOR_POSITION_X + EDITOR_SIZE_X - CLEAR_TEXT_W - 10 and mouse_x <= EDITOR_POSITION_X + EDITOR_SIZE_X and mouse_y >= EDITOR_POSITION_Y and mouse_y <= EDITOR_POSITION_Y + CLEAR_TEXT_H) then
		drawing = {};
		return;
	end

	if (mouse_x >= EDITOR_POSITION_X and mouse_x <= EDITOR_POSITION_X + EDITOR_SIZE_X and mouse_y >= EDITOR_POSITION_Y and mouse_y <= EDITOR_POSITION_Y + CLEAR_TEXT_H) then
		is_dragging = true;
		dragging_offset_x = mouse_x - EDITOR_POSITION_X;
		dragging_offset_y = mouse_y - EDITOR_POSITION_Y;
		return;
	end

	if (mouse_x >= EDITOR_POSITION_X + EDITOR_SIZE_X and mouse_x <= EDITOR_POSITION_X + EDITOR_SIZE_X + 10 and mouse_y >= EDITOR_POSITION_Y + EDITOR_SIZE_Y + CLEAR_TEXT_H + 3 and mouse_y <= EDITOR_POSITION_Y + EDITOR_SIZE_Y + CLEAR_TEXT_H + 3 + 10) then
		is_resizing = true;
		dragging_offset_x = mouse_x - EDITOR_POSITION_X;
		dragging_offset_y = mouse_y - EDITOR_POSITION_Y;
		return;
	end

	if (mouse_x <= EDITOR_POSITION_X or mouse_y <= EDITOR_POSITION_Y + CLEAR_TEXT_H or mouse_x >= EDITOR_POSITION_X + EDITOR_SIZE_X or mouse_y >= EDITOR_SIZE_Y + EDITOR_POSITION_Y + CLEAR_TEXT_H + 3) then
		return;
	end

	local points_in_radius = getPointsInRadius(mouse_x - EDITOR_POSITION_X, mouse_y - EDITOR_POSITION_Y, 20);
	if (#points_in_radius == 0) then
		table.insert(drawing, {x=mouse_x - EDITOR_POSITION_X, y=mouse_y - EDITOR_POSITION_Y});
	end
end

function rightMouseHandler(mouse_x, mouse_y)
	local points_in_radius = getPointsInRadius(mouse_x - EDITOR_POSITION_X, mouse_y - EDITOR_POSITION_Y, 20);

	for i=1, #points_in_radius do
		local point = points_in_radius[i];
		local remove_index = getTableIndex(drawing, point);

		if (remove_index ~= nil) then
			table.remove(drawing, remove_index);
		end
	end
end

function getTableIndex(tbl, check_point)
	for i=1, #tbl do
		local point = tbl[i];
		if (point.x == check_point.x and point.y == check_point.y) then
			return i;
		end
	end
	return nil
end

function getPointsInRadius(x, y, radius)
	local points_in_radius = {};
	for i=1, #drawing do
		local point = drawing[i];

		if (math.sqrt((x-point.x)^2 + (y-point.y)^2) <= radius) then
			table.insert(points_in_radius, drawing[i])
		end
	end
	return points_in_radius;
end

function gameEventHandler(event)
	if (event:GetName() == "weapon_fire") then
		local shooter_uid = event:GetInt('userid');
		local shooter_pid = client.GetPlayerIndexByUserID(shooter_uid);
		local self_pid = client.GetLocalPlayerIndex();

		if (shooter_pid == nil or shooter_pid ~= self_pid) then
			return;
		end

		if (is_shooting) then
			if (current_shoot_index == nil) then
				current_shoot_index = 0;
			end

			current_shoot_index = current_shoot_index + 1;
		end
	end

end

function moveEventHandler(cmd)
	va_x, va_y, va_z = cmd:GetViewAngles();

	if (is_shooting and #drawing > 0) then
		local local_player = entities.GetLocalPlayer();
		if (local_player == nil) then
			return;
		end

		local my_weapon = local_player:GetPropEntity("m_hActiveWeapon");
		if (my_weapon == nil) then
			return nil;
		end

		local weapon_inaccuracy = my_weapon:GetWeaponInaccuracy();

		if (current_shoot_index ~= nil and (weapon_inaccuracy - base_inaccuracy) / base_inaccuracy * 100 > INACCURACY_SL:GetValue()) then
			return;
		end

		local my_x, my_y, my_z = local_player:GetBonePosition(8);

		local target_angles = getTargetLocations(local_player);

		if (target_angles == nil) then
			return;
		end

		if (current_shoot_index == nil) then
			current_shoot_index = 1;
			center_va_x, center_va_y, center_va_z = va_x, va_y, va_z;
			base_inaccuracy = weapon_inaccuracy;
		end

		if (current_shoot_index == #target_angles) then
			current_shoot_index = nil;
			return;
		end

		local target = target_angles[current_shoot_index];
		if (target == nil) then
			return;
		end

		local va_x, va_y, va_z = getAngle(my_x, my_y, my_z, target.x, target.y, target.z);

		cmd:SetViewAngles(va_x, va_y, va_z);
		cmd:SetButtons(1);
	end
end

function getTargetLocations(local_player)
	if (local_player == nil) then
		return;
	end

	local target_angles = {};

	local my_x, my_y, my_z = local_player:GetAbsOrigin();
	local my_ax, my_ay, my_az = local_player:GetProp("m_angEyeAngles");
	local is_ducking = local_player:GetPropBool('localdata', 'm_Local', 'm_bDucking');

	local z_offset = 64;
	if (is_ducking == true) then
		z_offset = 46;
	end

	if (is_shooting and center_va_x ~= nil) then
		my_ax = center_va_x;
		my_ay = center_va_y;
		my_az = center_va_z;
	end

	for i=1, #drawing do
		local point = drawing[i];
		local vx_offset = math.atan(((EDITOR_SIZE_X / 2 - point.x)) / DRAW_DISTANCE) * SCALE_SL:GetValue();
		local vz_offset = math.atan(((EDITOR_SIZE_Y / 2 - (point.y + CLEAR_TEXT_H))) / DRAW_DISTANCE) * SCALE_SL:GetValue();

		local x = my_x - DRAW_DISTANCE * (math.cos(math.rad(my_ay + vx_offset + 180)));
		local y = my_y - DRAW_DISTANCE * (math.sin(math.rad(my_ay + vx_offset + 180)));
		local z = my_z - DRAW_DISTANCE * math.tan(math.rad(my_ax - vz_offset + 180)) + z_offset;

		table.insert(target_angles, {
			x=x,
			y=y,
			z=z
		});
	end

	return target_angles;
end


function vectorAngles(d_x, d_y, d_z)
	local t_x;
	local t_y;
	local t_z;
	if (d_x == 0 and d_y == 0) then
		if (d_z > 0) then
			t_x = 270;
		else
			t_x = 90;
		end
		t_y = 0;
	else
		t_x = math.atan(-d_z, math.sqrt(d_x ^ 2 + d_y ^ 2)) * -180 / math.pi;
		t_y = math.atan(d_y, d_x) * 180 / math.pi;

		if (t_y > 90) then
			t_y = t_y - 180;
		elseif (t_y < 90) then
			t_y = t_y + 180;
		elseif (t_y == 90) then
			t_y = 0;
		end
	end

	t_z = 0;

	return t_x, t_y, t_z;
end

function normalizeAngles(a_x, a_y, a_z)
	while (a_x > 89.0) do
		a_x = a_x - 180.;
	end

	while (a_x < -89.0) do
		a_x = a_x + 180.;
	end

	while (a_y > 180.) do
		a_y = a_y - 360;
	end

	while (a_y < -180.) do
		a_y = a_y + 360;
	end

	return a_x, a_y, a_z;
end

function getAngle(my_x, my_y, my_z, t_x, t_y, t_z)
	local d_x = my_x - t_x;
	local d_y = my_y - t_y;
	local d_z = my_z - t_z;

	local va_x, va_y, va_z = vectorAngles(d_x, d_y, d_z);
	return normalizeAngles(va_x, va_y, va_z);
end

function getDistanceToTarget(my_x, my_y, my_z, t_x, t_y, t_z)
	local dx = my_x - t_x;
	local dy = my_y - t_y;
	local dz = my_z - t_z;
	return math.sqrt(dx^2 + dy^2 + dz^2);
end

client.AllowListener("weapon_fire");
callbacks.Register("FireGameEvent", "drawbot_game_event", gameEventHandler);
callbacks.Register("Draw", "drawbot_draw_event", drawEditorHandler);
callbacks.Register("CreateMove", "drawbot_move_event", moveEventHandler);