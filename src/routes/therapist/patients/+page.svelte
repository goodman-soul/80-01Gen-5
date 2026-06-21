<script lang="ts">
	import type { PageData } from './$types';
	import type { Child } from '$lib/types';
	import { Search, User, Calendar, Plus, FileText } from 'lucide-svelte';
	import { goto } from '$app/navigation';

	export let data: PageData;

	let searchQuery = '';

	$: filteredPatients = (data.patients || []).filter((p) =>
		p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
		(p.nickname && p.nickname.toLowerCase().includes(searchQuery.toLowerCase()))
	);

	function calculateAge(birthDate: string | null): string {
		if (!birthDate) return '--';
		const birth = new Date(birthDate);
		const now = new Date();
		let age = now.getFullYear() - birth.getFullYear();
		const m = now.getMonth() - birth.getMonth();
		if (m < 0 || (m === 0 && now.getDate() < birth.getDate())) {
			age--;
		}
		return `${age}岁`;
	}

	async function assignHomework(childId: string) {
		await goto(`/therapist/assign?childId=${childId}`);
	}
</script>

<div class="max-w-6xl mx-auto px-4 py-8">
	<div class="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-6 gap-4">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">我的患者</h1>
			<p class="text-gray-500 text-sm">共 {data.patients?.length || 0} 位患者</p>
		</div>
		<div class="relative max-w-sm">
			<Search class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
			<input
				type="text"
				bind:value={searchQuery}
				class="input pl-10"
				placeholder="搜索患者姓名..."
			/>
		</div>
	</div>

	{#if filteredPatients.length === 0}
		<div class="card p-12 text-center">
			<User class="w-16 h-16 text-gray-300 mx-auto mb-4" />
			<p class="text-gray-500 mb-2">
				{searchQuery ? '未找到匹配的患者' : '暂无患者'}
			</p>
			<p class="text-sm text-gray-400">请联系管理员添加患者并分配给您</p>
		</div>
	{:else}
		<div class="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
			{#each filteredPatients as patient}
				<div class="card p-6 hover:shadow-md transition-shadow">
					<div class="flex items-start justify-between mb-4">
						<div class="flex items-center">
							<div class="w-14 h-14 bg-gradient-to-br from-primary-400 to-primary-600 rounded-full flex items-center justify-center text-white text-xl font-bold">
								{patient.name[0]}
							</div>
							<div class="ml-4">
								<h3 class="font-semibold text-gray-900">{patient.name}</h3>
								<p class="text-sm text-gray-500">
									{patient.nickname ? `${patient.nickname} · ` : ''}
									{calculateAge(patient.birth_date)}
								</p>
							</div>
						</div>
					</div>

					{#if patient.parent?.full_name}
						<div class="text-sm text-gray-600 mb-4">
							<p>家长：{patient.parent.full_name}</p>
							{#if patient.parent.phone}
								<p>联系电话：{patient.parent.phone}</p>
							{/if}
						</div>
					{/if}

					{#if patient.notes}
						<p class="text-sm text-gray-500 mb-4 line-clamp-2">{patient.notes}</p>
					{/if}

					<div class="flex gap-2">
						<a
							href={`/therapist/patients/${patient.id}`}
							class="btn btn-secondary flex-1 text-sm py-2"
						>
							<Calendar class="w-4 h-4 mr-1" />
							查看记录
						</a>
						<button
							on:click={() => assignHomework(patient.id)}
							class="btn btn-primary flex-1 text-sm py-2"
						>
							<Plus class="w-4 h-4 mr-1" />
							布置作业
						</button>
					</div>
				</div>
			{/each}
		</div>
	{/if}
</div>
