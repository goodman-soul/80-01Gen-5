<script lang="ts">
	import type { PageData } from './$types';
	import type { Profile, UserRole, Child } from '$lib/types';
	import { Search, Plus, Edit, Trash2, UserCog, Phone, Mail } from 'lucide-svelte';
	import { onMount } from 'svelte';

	export let data: PageData;

	let searchQuery = '';
	let selectedRole: UserRole | 'all' = 'all';
	let showAddModal = false;
	let showChildModal = false;
	let editingUser: Profile | null = null;

	let newUser = {
		email: '',
		password: '',
		full_name: '',
		phone: '',
		role: 'parent' as UserRole
	};

	let newChild = {
		name: '',
		nickname: '',
		birth_date: '',
		gender: '' as '' | 'male' | 'female' | 'other',
		parent_id: '',
		therapist_id: ''
	};

	const roleLabels: Record<string, string> = {
		admin: '管理员',
		therapist: '治疗师',
		parent: '家长'
	};

	const roleColors: Record<string, string> = {
		admin: 'bg-purple-100 text-purple-700',
		therapist: 'bg-green-100 text-green-700',
		parent: 'bg-blue-100 text-blue-700'
	};

	const genderLabels: Record<string, string> = {
		male: '男',
		female: '女',
		other: '其他'
	};

	const roleList: UserRole[] = ['admin', 'therapist', 'parent'];
	const genderList: ('male' | 'female' | 'other')[] = ['male', 'female', 'other'];

	$: filteredUsers = (data.users || []).filter((u) => {
		const matchSearch =
			u.full_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
			(u.phone && u.phone.includes(searchQuery));
		const matchRole = selectedRole === 'all' ? true : u.role === selectedRole;
		return matchSearch && matchRole;
	});

	$: parents = (data.users || []).filter((u) => u.role === 'parent');
	$: therapists = (data.users || []).filter((u) => u.role === 'therapist');

	function openAddModal() {
		newUser = { email: '', password: '', full_name: '', phone: '', role: 'parent' };
		editingUser = null;
		showAddModal = true;
	}

	function openEditModal(user: Profile) {
		editingUser = user;
		newUser = {
			email: '',
			password: '',
			full_name: user.full_name,
			phone: user.phone || '',
			role: user.role
		};
		showAddModal = true;
	}

	async function saveUser() {
		if (!newUser.full_name.trim()) {
			alert('请输入姓名');
			return;
		}

		try {
			if (editingUser) {
				const { error } = await data.supabase
					.from('profiles')
					.update({
						full_name: newUser.full_name,
						phone: newUser.phone,
						role: newUser.role
					})
					.eq('id', editingUser.id);

				if (error) throw error;
			} else {
				if (!newUser.email.trim() || !newUser.password.trim()) {
					alert('请输入邮箱和密码');
					return;
				}

				const { data: authData, error: authError } = await data.supabase.auth.admin
					? await data.supabase.auth.signUp({
							email: newUser.email,
							password: newUser.password,
							options: {
								data: {
									full_name: newUser.full_name
								}
							}
						})
					: { data: { user: { id: crypto.randomUUID() } }, error: null };

				if (authError) throw authError;

				const { error: profileError } = await data.supabase.from('profiles').insert({
					id: authData?.user?.id || crypto.randomUUID(),
					full_name: newUser.full_name,
					phone: newUser.phone,
					role: newUser.role,
					institution_id: data.profile?.institution_id
				});

				if (profileError) throw profileError;
			}

			alert('保存成功！');
			showAddModal = false;
			location.reload();
		} catch (err) {
			console.error(err);
			alert('保存失败：' + (err as Error).message);
		}
	}

	async function deleteUser(userId: string) {
		if (!confirm('确定要删除该用户吗？相关数据可能会丢失。')) return;

		const { error } = await data.supabase
			.from('profiles')
			.delete()
			.eq('id', userId);

		if (error) {
			alert('删除失败');
			return;
		}

		location.reload();
	}

	function openChildModal() {
		newChild = { name: '', nickname: '', birth_date: '', gender: '', parent_id: '', therapist_id: '' };
		showChildModal = true;
	}

	async function saveChild() {
		if (!newChild.name.trim()) {
			alert('请输入孩子姓名');
			return;
		}
		if (!newChild.parent_id) {
			alert('请选择家长');
			return;
		}

		const { error } = await data.supabase.from('children').insert({
			name: newChild.name,
			nickname: newChild.nickname || null,
			birth_date: newChild.birth_date || null,
			gender: newChild.gender || null,
			parent_id: newChild.parent_id,
			therapist_id: newChild.therapist_id || null
		});

		if (error) {
			console.error(error);
			alert('保存失败');
			return;
		}

		alert('添加成功！');
		showChildModal = false;
		location.reload();
	}

	async function deleteChild(childId: string) {
		if (!confirm('确定要删除该孩子信息吗？')) return;

		const { error } = await data.supabase
			.from('children')
			.delete()
			.eq('id', childId);

		if (error) {
			alert('删除失败');
			return;
		}

		location.reload();
	}
</script>

<div class="max-w-6xl mx-auto px-4 py-8">
	<div class="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-6 gap-4">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">用户管理</h1>
			<p class="text-gray-500 text-sm">管理机构内的所有用户和孩子</p>
		</div>
		<div class="flex gap-2">
			<button on:click={openChildModal} class="btn btn-secondary">
				<Plus class="w-5 h-5 mr-2" />
				添加孩子
			</button>
			<button on:click={openAddModal} class="btn btn-primary">
				<Plus class="w-5 h-5 mr-2" />
				添加用户
			</button>
		</div>
	</div>

	<div class="flex flex-col sm:flex-row gap-4 mb-6">
		<div class="relative flex-1 max-w-sm">
			<Search class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
			<input
				type="text"
				bind:value={searchQuery}
				class="input pl-10 w-full"
				placeholder="搜索姓名或手机号..."
			/>
		</div>
		<div class="flex gap-2 flex-wrap">
			<button
				on:click={() => (selectedRole = 'all')}
				class={`px-4 py-2 rounded-lg text-sm font-medium transition-colors {
					selectedRole === 'all'
						? 'bg-primary-500 text-white'
						: 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50'
				}`}
			>
				全部
			</button>
			{#each roleList as role}
				<button
					on:click={() => (selectedRole = role)}
					class={`px-4 py-2 rounded-lg text-sm font-medium transition-colors {
						selectedRole === role
							? 'bg-primary-500 text-white'
							: 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50'
					}`}
				>
					{roleLabels[role]}
				</button>
			{/each}
		</div>
	</div>

	<div class="card overflow-hidden mb-8">
		<div class="overflow-x-auto">
			<table class="w-full">
				<thead class="bg-gray-50">
					<tr>
						<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">用户</th>
						<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">角色</th>
						<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">联系方式</th>
						<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">注册时间</th>
						<th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">操作</th>
					</tr>
				</thead>
				<tbody class="divide-y divide-gray-100">
					{#if filteredUsers.length === 0}
						<tr>
							<td colspan="5" class="px-6 py-12 text-center text-gray-500">暂无用户</td>
						</tr>
					{/if}
					{#each filteredUsers as user}
						<tr class="hover:bg-gray-50">
							<td class="px-6 py-4">
								<div class="flex items-center">
									<div class="w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center text-gray-600 font-medium">
										{user.full_name[0]}
									</div>
									<div class="ml-3">
										<p class="font-medium text-gray-900">{user.full_name}</p>
										<p class="text-sm text-gray-500">{user.id.slice(0, 8)}...</p>
									</div>
								</div>
							</td>
							<td class="px-6 py-4">
								<span class={`badge ${roleColors[user.role]}`}>{roleLabels[user.role]}</span>
							</td>
							<td class="px-6 py-4">
								{#if user.phone}
									<p class="text-sm text-gray-700 flex items-center">
										<Phone class="w-4 h-4 mr-1 text-gray-400" />
										{user.phone}
									</p>
								{:else}
									<p class="text-sm text-gray-400">未设置</p>
								{/if}
							</td>
							<td class="px-6 py-4 text-sm text-gray-500">
								{new Date(user.created_at).toLocaleDateString('zh-CN')}
							</td>
							<td class="px-6 py-4 text-right">
								<div class="flex justify-end gap-2">
									<button
										on:click={() => openEditModal(user)}
										class="p-2 text-gray-400 hover:text-primary-600 hover:bg-primary-50 rounded-lg"
									>
										<Edit class="w-5 h-5" />
									</button>
									<button
										on:click={() => deleteUser(user.id)}
										class="p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-lg"
									>
										<Trash2 class="w-5 h-5" />
									</button>
								</div>
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	</div>

	<h2 class="text-xl font-bold text-gray-900 mb-4">孩子列表</h2>
	<div class="card overflow-hidden">
		<div class="overflow-x-auto">
			<table class="w-full">
				<thead class="bg-gray-50">
					<tr>
						<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">孩子</th>
						<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">家长</th>
						<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">治疗师</th>
						<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">生日/性别</th>
						<th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">操作</th>
					</tr>
				</thead>
				<tbody class="divide-y divide-gray-100">
					{#if !data.children || data.children.length === 0}
						<tr>
							<td colspan="5" class="px-6 py-12 text-center text-gray-500">暂无孩子</td>
						</tr>
					{/if}
					{#each data.children || [] as child}
						<tr class="hover:bg-gray-50">
							<td class="px-6 py-4">
								<div class="flex items-center">
									<div class="w-10 h-10 bg-gradient-to-br from-primary-400 to-primary-600 rounded-full flex items-center justify-center text-white font-medium">
										{child.name[0]}
									</div>
									<div class="ml-3">
										<p class="font-medium text-gray-900">{child.name}</p>
										{#if child.nickname}
											<p class="text-sm text-gray-500">{child.nickname}</p>
										{/if}
									</div>
								</div>
							</td>
							<td class="px-6 py-4 text-sm text-gray-700">
								{child.parent?.full_name || '未关联'}
							</td>
							<td class="px-6 py-4 text-sm text-gray-700">
								{(() => {
									const t = therapists.find((th) => th.id === child.therapist_id);
									return t?.full_name || '未分配';
								})()}
							</td>
							<td class="px-6 py-4 text-sm text-gray-500">
								{child.birth_date || '--'} / {child.gender ? genderLabels[child.gender] : '--'}
							</td>
							<td class="px-6 py-4 text-right">
								<button
									on:click={() => deleteChild(child.id)}
									class="p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-lg"
								>
									<Trash2 class="w-5 h-5" />
								</button>
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	</div>

	{#if showAddModal}
		<div class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
			<div class="card p-6 w-full max-w-md max-h-[90vh] overflow-y-auto">
				<h3 class="text-xl font-bold text-gray-900 mb-6">
					{editingUser ? '编辑用户' : '添加用户'}
				</h3>
				<div class="space-y-4">
					{#if !editingUser}
						<div>
							<label class="label" for="user-email">邮箱 *</label>
							<input id="user-email" type="email" bind:value={newUser.email} class="input" required />
						</div>
						<div>
							<label class="label" for="user-password">初始密码 *</label>
							<input id="user-password" type="password" bind:value={newUser.password} class="input" required />
						</div>
					{/if}
					<div>
						<label class="label" for="user-full-name">姓名 *</label>
						<input id="user-full-name" type="text" bind:value={newUser.full_name} class="input" required />
					</div>
					<div>
						<label class="label" for="user-phone">手机号</label>
						<input id="user-phone" type="tel" bind:value={newUser.phone} class="input" />
					</div>
					<div>
						<label class="label" for="user-role">角色</label>
						<select id="user-role" bind:value={newUser.role} class="input">
							{#each roleList as role}
								<option value={role}>{roleLabels[role]}</option>
							{/each}
						</select>
					</div>
				</div>
				<div class="flex justify-end gap-3 mt-6">
					<button on:click={() => (showAddModal = false)} class="btn btn-secondary">取消</button>
					<button on:click={saveUser} class="btn btn-primary">保存</button>
				</div>
			</div>
		</div>
	{/if}

	{#if showChildModal}
		<div class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
			<div class="card p-6 w-full max-w-md max-h-[90vh] overflow-y-auto">
				<h3 class="text-xl font-bold text-gray-900 mb-6">添加孩子</h3>
				<div class="space-y-4">
					<div>
						<label class="label" for="child-name">姓名 *</label>
						<input id="child-name" type="text" bind:value={newChild.name} class="input" required />
					</div>
					<div>
						<label class="label" for="child-nickname">小名</label>
						<input id="child-nickname" type="text" bind:value={newChild.nickname} class="input" />
					</div>
					<div class="grid grid-cols-2 gap-4">
						<div>
							<label class="label" for="child-birth-date">出生日期</label>
							<input id="child-birth-date" type="date" bind:value={newChild.birth_date} class="input" />
						</div>
						<div>
							<label class="label" for="child-gender">性别</label>
							<select id="child-gender" bind:value={newChild.gender} class="input">
								<option value="">请选择</option>
								<option value="male">男</option>
								<option value="female">女</option>
								<option value="other">其他</option>
							</select>
						</div>
					</div>
					<div>
						<label class="label" for="child-parent">家长 *</label>
						<select id="child-parent" bind:value={newChild.parent_id} class="input" required>
							<option value="">请选择家长</option>
							{#each parents as p}
								<option value={p.id}>{p.full_name}</option>
							{/each}
						</select>
					</div>
					<div>
						<label class="label" for="child-therapist">治疗师</label>
						<select id="child-therapist" bind:value={newChild.therapist_id} class="input">
							<option value="">请选择治疗师</option>
							{#each therapists as t}
								<option value={t.id}>{t.full_name}</option>
							{/each}
						</select>
					</div>
				</div>
				<div class="flex justify-end gap-3 mt-6">
					<button on:click={() => (showChildModal = false)} class="btn btn-secondary">取消</button>
					<button on:click={saveChild} class="btn btn-primary">保存</button>
				</div>
			</div>
		</div>
	{/if}
</div>
