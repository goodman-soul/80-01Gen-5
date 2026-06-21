<script lang="ts">
	import type { PageData } from './$types';
	import { Building, Phone, MapPin, Save } from 'lucide-svelte';
	import { onMount } from 'svelte';

	export let data: PageData;

	let name = '';
	let address = '';
	let contact_phone = '';
	let loading = false;

	onMount(() => {
		if (data.institution) {
			name = data.institution.name;
			address = data.institution.address || '';
			contact_phone = data.institution.contact_phone || '';
		}
	});

	async function saveSettings() {
		if (!name.trim()) {
			alert('请输入机构名称');
			return;
		}

		loading = true;

		try {
			if (data.institution) {
				const { error } = await data.supabase
					.from('institutions')
					.update({ name, address, contact_phone })
					.eq('id', data.institution.id);

				if (error) throw error;
			} else {
				const { data: newInst, error } = await data.supabase
					.from('institutions')
					.insert({ name, address, contact_phone })
					.select()
					.single();

				if (error || !newInst) throw error;

				await data.supabase
					.from('profiles')
					.update({ institution_id: newInst.id })
					.eq('id', data.profile?.id);
			}

			alert('保存成功！');
			location.reload();
		} catch (err) {
			console.error(err);
			alert('保存失败，请重试');
		} finally {
			loading = false;
		}
	}
</script>

<div class="max-w-3xl mx-auto px-4 py-8">
	<div class="mb-6">
		<h1 class="text-2xl font-bold text-gray-900">机构设置</h1>
		<p class="text-gray-500 text-sm">管理您机构的基本信息</p>
	</div>

	<div class="card p-8">
		<div class="flex items-center mb-6">
			<div class="w-16 h-16 bg-primary-100 rounded-2xl flex items-center justify-center">
				<Building class="w-8 h-8 text-primary-600" />
			</div>
			<div class="ml-4">
				<h2 class="text-lg font-semibold text-gray-900">机构信息</h2>
				<p class="text-sm text-gray-500">这些信息会显示给家长和治疗师</p>
			</div>
		</div>

		<div class="space-y-6">
			<div>
				<label class="label">机构名称 *</label>
				<div class="relative">
					<Building class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
					<input
						type="text"
						bind:value={name}
						class="input pl-10"
						placeholder="如：阳光儿童康复中心"
						required
					/>
				</div>
			</div>

			<div>
				<label class="label">机构地址</label>
				<div class="relative">
					<MapPin class="absolute left-3 top-3 w-5 h-5 text-gray-400" />
					<textarea
						bind:value={address}
						class="input pl-10 min-h-[80px]"
						placeholder="请输入机构详细地址"
					/>
				</div>
			</div>

			<div>
				<label class="label">联系电话</label>
				<div class="relative">
					<Phone class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
					<input
						type="tel"
						bind:value={contact_phone}
						class="input pl-10"
						placeholder="如：400-123-4567"
					/>
				</div>
			</div>
		</div>

		<div class="mt-8 pt-6 border-t border-gray-100 flex justify-end">
			<button on:click={saveSettings} class="btn btn-primary" disabled={loading}>
				<Save class="w-5 h-5 mr-2" />
				{loading ? '保存中...' : '保存设置'}
			</button>
		</div>
	</div>

	<div class="card p-8 mt-6">
		<h2 class="text-lg font-semibold text-gray-900 mb-4">系统信息</h2>
		<div class="space-y-3 text-sm">
			<div class="flex justify-between">
				<span class="text-gray-500">系统版本</span>
				<span class="text-gray-900">v1.0.0</span>
			</div>
			<div class="flex justify-between">
				<span class="text-gray-500">当前用户角色</span>
				<span class="badge bg-purple-100 text-purple-700">管理员</span>
			</div>
			<div class="flex justify-between">
				<span class="text-gray-500">机构用户数</span>
				<span class="text-gray-900">{data.users?.length || 0} 人</span>
			</div>
		</div>
	</div>
</div>
